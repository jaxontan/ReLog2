import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NotificationPayload {
  type: 'chat' | 'memory' | 'system'
  title: string
  body: string
  album_id?: string
  memory_id?: string
  message_id?: string
  sender_id?: string
  exclude_user_id?: string // Don't notify the sender
}

// Get OAuth 2.0 access token from service account
async function getAccessToken(): Promise<string> {
  const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
  if (!serviceAccountJson) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT secret not configured')
  }
  const serviceAccount = JSON.parse(serviceAccountJson)

  const now = Math.floor(Date.now() / 1000)
  const header = { alg: 'RS256', typ: 'JWT' }
  const claim = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  }

  // Import private key for signing
  const privateKey = serviceAccount.private_key
  const encoder = new TextEncoder()

  // Create JWT
  const headerB64 = btoa(JSON.stringify(header)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
  const claimB64 = btoa(JSON.stringify(claim)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
  const signingInput = `${headerB64}.${claimB64}`

  // Sign with RSA-SHA256
  const key = await crypto.subtle.importKey(
    'pkcs8',
    new Uint8Array(privateKey
      .replace('-----BEGIN PRIVATE KEY-----', '')
      .replace('-----END PRIVATE KEY-----', '')
      .replace(/\n/g, '')
      .split('')
      .map(c => c.charCodeAt(0))
    ),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  )

  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, encoder.encode(signingInput))
  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')

  const jwt = `${signingInput}.${signatureB64}`

  // Exchange JWT for access token
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  const tokenData = await tokenResponse.json()
  if (!tokenResponse.ok) {
    throw new Error(`Failed to get access token: ${JSON.stringify(tokenData)}`)
  }
  return tokenData.access_token
}

// Send message via FCM HTTP v1 API
async function sendFcmMessage(accessToken: string, tokens: string[], payload: NotificationPayload): Promise<{ successCount: number; failureCount: number; failedTokens: string[] }> {
  const projectId = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') || '{}').project_id
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:sendBatch`

  const messages = tokens.map(token => ({
    message: {
      token,
      notification: { title: payload.title, body: payload.body },
      data: {
        type: payload.type,
        album_id: payload.album_id || '',
        memory_id: payload.memory_id || '',
        message_id: payload.message_id || '',
      },
      android: { priority: 'HIGH' },
      apns: { payload: { aps: { sound: 'default' } } },
      webpush: { notification: { icon: '/icons/icon-192.png' } },
    },
  }))

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ messages }),
  })

  const result = await response.json()
  if (!response.ok) {
    throw new Error(`FCM batch send failed: ${JSON.stringify(result)}`)
  }

  const failedTokens: string[] = []
  let successCount = 0
  let failureCount = 0

  if (result.responses) {
    result.responses.forEach((resp: any, i: number) => {
      if (resp.error) {
        failureCount++
        if (resp.error.code === 'UNREGISTERED' || resp.error.code === 'INVALID_ARGUMENT') {
          failedTokens.push(tokens[i])
        }
      } else {
        successCount++
      }
    })
  }

  return { successCount, failureCount, failedTokens }
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const payload: NotificationPayload = await req.json()

    // Initialize Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get FCM tokens for recipients
    let query = supabase
      .from('device_tokens')
      .select('token, user_id, platform')

    // If album_id provided, get members of that album
    if (payload.album_id) {
      const { data: members } = await supabase
        .from('members')
        .select('user_id')
        .eq('album_id', payload.album_id)

      const memberIds = members?.map(m => m.user_id) ?? []
      const filtered = payload.exclude_user_id
        ? memberIds.filter(id => id !== payload.exclude_user_id)
        : memberIds

      query = query.in('user_id', filtered)
    }

    // If specific user_id provided (without album)
    if (payload.sender_id && !payload.album_id) {
      query = query.eq('user_id', payload.sender_id)
    }

    const { data: tokens, error: tokensError } = await query

    if (tokensError) {
      throw tokensError
    }

    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ success: true, message: 'No tokens to send to' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get OAuth access token
    const accessToken = await getAccessToken()

    // Send via FCM HTTP v1 API
    const registrationTokens = tokens.map(t => t.token)
    const result = await sendFcmMessage(accessToken, registrationTokens, payload)

    // Clean up invalid tokens
    if (result.failedTokens.length > 0) {
      await supabase.from('device_tokens').delete().in('token', result.failedTokens)
    }

    return new Response(
      JSON.stringify({
        success: true,
        successCount: result.successCount,
        failureCount: result.failureCount,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Notification error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})