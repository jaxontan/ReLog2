# Custom Memory Book — Design Specification

**Project:** ReLog2 (Flutter travel album app)
**Feature:** Custom Memory Book (Digital + Print)
**Date:** 2026-07-17
**Status:** Draft — Awaiting Review
**Approach:** Modular Feature-First (Approach 1 from brainstorming)

---

## 1. Executive Summary

### 1.1 Product Vision
Transform ReLog2 travel albums into beautiful, keepsake-quality **custom memory books** — digital-first with optional print-on-demand. Each book captures a trip's complete story: photos, videos (via QR), voice notes (via QR), timeline notes across 4 phases, map journey, and contributor credits.

### 1.2 Unique Differentiators vs. 识趣出版 / Shutterfly / Chatbooks
| Differentiator | ReLog2 Approach |
|----------------|-----------------|
| **Photobooth 3-grid strips** | Auto-generated from trip photos; inserts as fun "film strip" pages |
| **QR-linked media** | Videos & voice notes play in-app / on web via scanned QR codes |
| **Phase-aware narrative** | Before / Mid / Confession / After trip notes as chapter dividers |
| **Map journey spreads** | GPS waypoints → illustrated map pages with memory pins |
| **Group-first** | All companions contribute; book reflects shared experience |
| **Digital-first, print-optional** | Free digital flipbook; $3.99 unlock; print via POD partner |

### 1.3 Phased Delivery
| Phase | Scope | Timeline | Validation Gate |
|-------|-------|----------|-----------------|
| **1A** | Digital Book Core (PDF + flipbook, 4 templates, QR media, map spreads, commerce) | 3-4 weeks | ≥15% of ended albums generate a book; ≥5% pay $3.99 |
| **1B** | Photobooth Strips (5 strip templates, auto-grouping, book inserts + standalone) | 2-3 weeks | ≥20% of book creators add strips |
| **1C** | Print-on-Demand Integration (Peecho API, print-ready PDF, checkout flow) | 2-3 weeks | ≥3% of paid books order print; unit economics positive |
| **1D** | Event Kiosk Mode (local printer, photobooth strips on-site) | 2 weeks | Event pilot: 50+ strips printed/day |

---

## 2. User Flows

### 2.1 Primary Flow: Create Digital Memory Book
```
Album Detail (ended trip)
    │
    ├─▶ "Create Memory Book" button (enabled when album.status == 'ended')
    │
    ▼
Book Builder Screen
    │  ├─ Template picker (4 thumbnails)
    │  ├─ Live preview (flipbook)
    │  ├─ Section toggles: [Memories] [Map] [Strips] [Contributors] [QR Index]
    │  ├─ Cover designer: title, subtitle, cover photo, style
    │  └─ "Generate Preview" → async PDF generation (2-5s)
    │
    ▼
Book Preview Screen (flipbook viewer)
    │  ├─ Swipe pages, tap QR → inline video/voice player
    │  ├─ Share link (copies web viewer URL)
    │  ├─ "Unlock Full Book" ($3.99) — RevenueCat purchase
    │  └─ "Order Print" (Phase 1C) — redirects to Peecho checkout
    │
    ▼
Unlocked Book → Full PDF download, unlimited regenerations, all members access
```

### 2.2 Photobooth Strip Flow (Phase 1B)
```
Book Builder → "Add Photobooth Strips" section
    │
    ▼
Strip Builder Screen
    │  ├─ Auto-groups 9 photos → 3 strips by date/location/faces
    │  ├─ Manual override: drag photos between strips
    │  ├─ Template picker per strip (5 styles)
    │  ├─ Caption per photo (optional)
    │  └─ "Add to Book" → inserts as pages after memories
    │
    ▼
Standalone Strip Download (PNG/PDF) — available without book purchase
```

### 2.3 Print Order Flow (Phase 1C)
```
Book Preview → "Order Print" button
    │
    ▼
Print Options Bottom Sheet
    │  ├─ Size: 6×9" / 8.5×11" / A5
    │  ├─ Binding: Softcover / Hardcover / Layflat
    │  ├─ Paper: Standard / Premium matte / Premium glossy
    │  ├─ Quantity: 1-10
    │  └─ Shipping address (prefill from profile)
    │
    ▼
Peecho Hosted Checkout (webview or external browser)
    │  ├─ Price calculated: base + pages + binding + shipping
    │  ├─ Payment: Stripe (cards, Apple Pay, Google Pay)
    │  └─ Order confirmation → email + push notification
    │
    ▼
Order Tracking Screen (in app) — Peecho webhook → Supabase → push updates
```

---

## 3. Data Models

### 3.1 Book Template (Static Config)
```dart
// lib/features/books/data/models/book_template.dart
enum BookTemplateId { travelJournal, minimal, magazine, photoboothEnhanced }

class BookTemplate {
  final BookTemplateId id;
  final String name;
  final String description;
  final String thumbnailAsset;  // asset path for picker
  final List<PageTemplate> pageTemplates;  // ordered page types
  final CoverTemplate coverTemplate;
  final Map<String, dynamic> styleTokens; // colors, fonts, spacing overrides
}

class PageTemplate {
  final PageType type;  // cover, toc, mapSpread, phaseDivider, memoryGrid, memoryFull, stripInsert, contributors, qrIndex
  final int minItems;   // min memories to render this page type
  final int maxItemsPerPage;
  final LayoutConfig layout;  // grid, full-bleed, caption-below, etc.
}

class CoverTemplate {
  final CoverStyle style; // photoFull, photoWithTitle, minimal, mapSilhouette
  final List<CoverField> editableFields; // title, subtitle, dateRange, location, coverPhoto
}
```

### 3.2 Book Instance (Generated per Album)
```dart
// lib/features/books/data/models/memory_book.dart
class MemoryBook {
  final String id;           // UUID
  final String albumId;      // FK to albums
  final BookTemplateId templateId;
  final BookCover cover;     // user-customized cover data
  final List<BookPage> pages; // ordered, generated
  final BookStatus status;   // draft | preview | unlocked | printed
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;         // increment on regenerate
}

class BookPage {
  final String id;           // UUID
  final PageType type;
  final int orderIndex;
  final PageContent content; // polymorphic: MemoryPageContent, MapPageContent, StripPageContent, etc.
  final LayoutConfig layout; // resolved from template + content
}

class BookCover {
  final String title;
  final String? subtitle;
  final String? coverPhotoStoragePath; // Supabase Storage path
  final DateTime? dateRangeStart;
  final DateTime? dateRangeEnd;
  final String? primaryLocation;
  final CoverStyle style;
}
```

### 3.3 Print Order (Phase 1C)
```dart
// lib/features/books/data/models/print_order.dart
class PrintOrder {
  final String id;              // UUID
  final String bookId;          // FK to MemoryBook
  final String userId;          // purchaser
  final PrintSpec spec;         // size, binding, paper, quantity
  final ShippingAddress address;
  final PrintOrderStatus status; // pending | confirmed | printing | shipped | delivered | failed
  final String peechoOrderId;   // external reference
  final double totalAmount;     // USD cents
  final DateTime createdAt;
  final DateTime? estimatedDelivery;
  final String? trackingNumber;
  final String? trackingUrl;
}
```

### 3.4 Photobooth Strip (Phase 1B)
```dart
// lib/features/photobooth/data/models/photobooth_strip.dart
class PhotoboothStrip {
  final String id;
  final String albumId;
  final List<StripPhoto> photos;  // exactly 3
  final StripTemplateId templateId;
  final String? caption;
  final DateTime createdAt;
  final String? generatedImagePath; // Supabase Storage: rendered strip PNG
}

class StripPhoto {
  final String memoryId;        // FK to memory (photo type)
  final int position;           // 0, 1, 2
  final String? caption;
  final Rect? cropRect;         // normalized 0-1 for pan/zoom
}
```

---

## 4. Architecture

### 4.1 Directory Structure (Feature-First + Shared Core)
```
lib/
├── core/
│   └── book/                          # SHARED: extracted after 1A+1B
│       ├── rendering/
│       │   ├── pdf_renderer.dart          # pdf package wrapper
│       │   ├── flipbook_renderer.dart     # page-turn animation
│       │   ├── qr_generator.dart          # QR codes for media URLs
│       │   └── map_renderer.dart          # static map image for spreads
│       ├── templates/
│       │   ├── template_registry.dart     # all BookTemplate definitions
│       │   ├── page_composer.dart         # composes PageContent → PDF page
│       │   └── layout_engine.dart         # constraint-based layout
│       └── storage/
│           └── book_storage_service.dart  # upload PDF to Supabase Storage
│
├── features/
│   ├── books/                          # PHASE 1A + 1C
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── book_template.dart
│   │   │   │   ├── memory_book.dart
│   │   │   │   └── print_order.dart
│   │   │   ├── services/
│   │   │   │   ├── pdf_generator_service.dart      # orchestrates core.book.rendering
│   │   │   │   ├── book_storage_service.dart
│   │   │   │   ├── peecho_api_client.dart          # Phase 1C
│   │   │   │   └── revenue_cat_service.dart        # commerce
│   │   │   └── repositories/
│   │   │       ├── book_repository.dart
│   │   │       └── print_order_repository.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── use_cases/
│   │   │       ├── generate_book_preview.dart
│   │   │       ├── unlock_book.dart
│   │   │       ├── regenerate_book.dart
│   │   │       ├── download_book_pdf.dart
│   │   │       └── create_print_order.dart
│   │   └── presentation/
│   │       ├── view_models/
│   │       │   ├── book_builder_viewmodel.dart
│   │       │   ├── book_preview_viewmodel.dart
│   │       │   └── print_order_viewmodel.dart
│   │       ├── views/
│   │       │   ├── book_builder_screen.dart
│   │       │   ├── book_preview_screen.dart
│   │       │   ├── template_picker_bottom_sheet.dart
│   │       │   ├── cover_designer_sheet.dart
│   │       │   └── print_options_sheet.dart
│   │       └── widgets/
│   │           ├── flipbook_viewer.dart
│   │           ├── page_thumbnail_grid.dart
│   │           ├── qr_media_player.dart
│   │           └── template_preview_card.dart
│   │
│   ├── photobooth/                     # PHASE 1B
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── photobooth_strip.dart
│   │   │   ├── services/
│   │   │   │   └── strip_renderer_service.dart  # uses core.book.rendering
│   │   │   └── repositories/
│   │   │       └── photobooth_repository.dart
│   │   ├── domain/
│   │   │   └── use_cases/
│   │   │       ├── generate_strips_from_memories.dart
│   │   │       ├── render_strip_image.dart
│   │   │       └── add_strips_to_book.dart
│   │   └── presentation/
│   │       ├── view_models/
│   │       │   └── strip_builder_viewmodel.dart
│   │       ├── views/
│   │       │   ├── strip_builder_screen.dart
│   │       │   ├── strip_template_picker.dart
│   │       │   └── strip_preview_sheet.dart
│   │       └── widgets/
│   │           ├── strip_canvas.dart
│   │           ├── photo_slot.dart
│   │           └── caption_editor.dart
│   │
│   └── kiosk/                          # PHASE 1D (future)
│       └── ...                         # separate PRD
```

### 4.2 Layer Responsibilities
| Layer | Responsibility | Example |
|-------|----------------|---------|
| **View** | Pure UI, no logic | `BookBuilderScreen`, `FlipbookViewer` |
| **ViewModel** | UI state, user actions → UseCases | `BookBuilderViewModel` |
| **UseCase** | Single business operation, orchestrates repos/services | `GenerateBookPreview` |
| **Repository** | Data coordination, caching, offline | `BookRepository` |
| **Service** | External SDK wrappers, stateless utilities | `PdfGeneratorService`, `PeechoApiClient` |
| **Core.Book** | Reusable rendering/layout/QR primitives | `PdfRenderer`, `LayoutEngine` |

### 4.3 Key Data Flows

#### Generate Book Preview
```
BookBuilderViewModel.generatePreview()
    → GenerateBookPreviewUseCase.execute(albumId, templateId, coverData)
        → BookRepository.getAlbumMemories(albumId)
        → PdfGeneratorService.generate(memories, template, cover)
            → core.book.rendering.PdfRenderer.render(pages)
            → core.book.storage.BookStorageService.uploadPdf(pdfBytes)
        → BookRepository.saveBookPreview(MemoryBook)
    → ViewModel updates state → BookPreviewScreen shows flipbook
```

#### Unlock Book (Commerce)
```
BookPreviewViewModel.purchaseUnlock()
    → RevenueCatService.purchase('book_unlock_399')
        → onSuccess: UnlockBookUseCase.execute(bookId)
            → BookRepository.updateStatus(bookId, BookStatus.unlocked)
            → Grant access to all album members (via Firestore subcollection)
    → ViewModel navigates to unlocked BookPreviewScreen
```

---

## 5. PDF Generation Specification

### 5.1 Print-Ready PDF Requirements
| Spec | Value |
|------|-------|
| Page size | Configurable per template (default 6×9" = 152.4×228.6mm) |
| Bleed | 3mm all sides |
| Color space | CMYK (print) / sRGB (digital) |
| Resolution | 300 DPI for images |
| Fonts | Embedded subset (Noto Serif, Noto Sans, custom serif for journal) |
| Page count | 30-400 (partner limits) |
| File format | PDF/X-1a:2001 (print) / PDF 1.7 (digital) |

### 5.2 Page Composition Logic
```
For each album memory (sorted by capturedAt):
  1. Group by notePhase: before → mid → confession → after → photo/video/voice (no phase)
  2. For each phase with memories:
       - Insert PhaseDividerPage(phase)
       - Layout memories in grid (2×2, 1×2, or 1×1 based on count + template)
  3. If any memory has lat/lng:
       - Insert MapSpreadPage(all geotagged memories)
  4. If photobooth strips exist (Phase 1B):
       - Insert StripInsertPages (3 strips per spread)
  5. Insert ContributorsPage(all album members)
  6. Insert QRIndexPage(all video/voice memories with short codes)
```

### 5.3 QR Code Specification
- **Content**: `https://relog2.app/m/{memoryId}?t={signedToken}` (deep link to web viewer)
- **Size**: 25mm × 25mm (minimum 18mm for scan reliability)
- **Error correction**: Level M (15% damage tolerance)
- **Style**: Rounded corners, ReLog2 primary color, small logo in center
- **Placement**: Bottom-right of memory page, or dedicated QR Index page

---

## 6. Commerce & Pricing

### 6.1 Digital Products
| Product | Price | Unlocks | RevenueCat ID |
|---------|-------|---------|---------------|
| Book Unlock | $3.99 | Full PDF download, unlimited regenerations, all members access | `book_unlock_399` |
| Photobooth Strips | $1.99 | Standalone strip downloads, strips inserted in book | `strips_unlock_199` |
| Bundle (Book + Strips) | $4.99 | Both above | `book_strips_bundle_499` |

### 6.2 Print Pricing (Phase 1C — Peecho Base + Markup)
| Spec | Base Cost (est.) | Retail Price | Margin |
|------|------------------|--------------|--------|
| 6×9" Softcover, 50pp | $8.50 | $19.99 | 57% |
| 6×9" Hardcover, 50pp | $14.20 | $29.99 | 53% |
| 8.5×11" Layflat, 50pp | $22.80 | $44.99 | 49% |
| + per extra 10pp | +$0.80 | +$2.00 | 60% |

*Prices include shipping to US/CA/EU. Asia/other calculated at checkout.*

### 6.3 Revenue Sharing
- **Apple/Google**: 15-30% on digital unlocks (IAP)
- **Stripe**: 2.9% + $0.30 on print orders
- **Peecho**: Base cost deducted at source
- **Net to ReLog2**: ~65% digital, ~45% print

---

## 7. Technical Requirements

### 7.1 Dependencies (Add to pubspec.yaml)
```yaml
dependencies:
  # PDF Generation
  pdf: ^3.10.0
  printing: ^5.11.0
  
  # QR Codes
  qr_flutter: ^4.1.0
  
  # Flipbook Viewer
  page_turn: ^2.0.0   # or custom PageView with transform
  
  # Image Processing (for strips)
  image: ^4.1.0
  image_editor: ^1.0.0  # or custom crop/zoom
  
  # Commerce
  purchases_flutter: ^6.0.0  # RevenueCat
  
  # Maps (static images for PDF)
  static_map: ^1.0.0  # or generate via Mapbox Static API
  
  # Supabase Storage (already in project)
  supabase_flutter: ^2.3.0
```

### 7.2 Supabase Schema Additions
```sql
-- books/memory_books
create table memory_books (
  id uuid primary key default gen_random_uuid(),
  album_id uuid not null references albums(id) on delete cascade,
  template_id text not null,
  cover_data jsonb not null,
  pages_data jsonb not null,
  status text not null check (status in ('draft','preview','unlocked','printed')),
  version int not null default 1,
  pdf_storage_path text,
  pdf_updated_at timestamptz,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_memory_books_album on memory_books(album_id);

-- books/print_orders
create table print_orders (
  id uuid primary key default gen_random_uuid(),
  book_id uuid not null references memory_books(id) on delete cascade,
  user_id uuid not null references auth.users(id),
  spec jsonb not null,  -- PrintSpec serialized
  shipping_address jsonb not null,
  status text not null check (status in ('pending','confirmed','printing','shipped','delivered','failed')),
  peecho_order_id text,
  total_amount_cents int not null,
  tracking_number text,
  tracking_url text,
  estimated_delivery timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- photobooth/photobooth_strips
create table photobooth_strips (
  id uuid primary key default gen_random_uuid(),
  album_id uuid not null references albums(id) on delete cascade,
  template_id text not null,
  photo_memory_ids uuid[3] not null,
  captions text[3],
  crop_data jsonb[3],
  rendered_image_path text,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create index idx_photobooth_strips_album on photobooth_strips(album_id);

-- RLS policies: users can read/write their own album's books/strips/orders
```

### 7.3 Supabase Edge Functions (Phase 1C)
```
supabase/functions/
├── peecho-webhook/        # Receives Peecho order updates → updates print_orders table
├── generate-print-pdf/    # Optional: server-side PDF for large books (>200pp)
└── refresh-qr-tokens/     # Cron: refreshes signed URLs for QR codes (7-day expiry)
```

---

## 8. UI/UX Specification

### 8.1 Book Builder Screen
```
┌─────────────────────────────────────┐
│ AppBar: "Create Memory Book"        │
├─────────────────────────────────────┤
│ Template Picker (horizontal scroll) │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐         │
│ │ 📖 │ │ ✨ │ │ 📰 │ │ 🎞 │         │
│ │Trvl│ │ Min│ │ Mag│ │ Photo│        │
│ └────┘ └────┘ └────┘ └────┘         │
├─────────────────────────────────────┤
│ Cover Designer (collapsible)        │
│ ┌─────────────────────────────────┐ │
│ │ [Cover Photo]  Title: "Japan    │ │
│ │                2024"            │ │
│ │ Subtitle: "Tokyo→Kyoto→Osaka"   │ │
│ │ Style: [Photo Full ▼]           │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ Section Toggles                     │
│ ☑ Memories    ☑ Map    ☐ Strips     │
│ ☑ Contributors  ☑ QR Index          │
├─────────────────────────────────────┤
│ [Generate Preview]  (Primary BTN)   │
└─────────────────────────────────────┘
```

### 8.2 Flipbook Viewer (Book Preview)
- **Library**: `page_turn` or custom `PageView` with 3D transform
- **Gestures**: Swipe → page turn; Double-tap → zoom; Tap QR → inline player
- **Toolbar**: Share, Download PDF (if unlocked), Purchase Unlock, Order Print
- **Loading**: Skeleton pages while PDF generates (show progress %)

### 8.3 Photobooth Strip Builder (Phase 1B)
```
┌─────────────────────────────────────┐
│ AppBar: "Photobooth Strips"         │
├─────────────────────────────────────┤
│ Strip 1 of 3                        │
│ ┌─────────────────────────────────┐ │
│ │ [Photo 1] [Photo 2] [Photo 3]   │ │  ← Template preview
│ │  "Sushi"  "Temple"  "Sunset"    │ │
│ └─────────────────────────────────┘ │
│ Template: [Film Strip ▼] [Clean ▼]  │
│ [Shuffle Photos] [Add Caption]      │
├─────────────────────────────────────┤
│ Strip 2 of 3  ...                   │
├─────────────────────────────────────┤
│ Strip 3 of 3  ...                   │
├─────────────────────────────────────┤
│ [Add to Book]  [Download Strips]    │
└─────────────────────────────────────┘
```

---

## 9. Testing Strategy

### 9.1 Unit Tests
| Target | Coverage Goal |
|--------|---------------|
| `PdfGeneratorService` | 90% — page composition logic, template selection |
| `LayoutEngine` | 85% — constraint solving, overflow handling |
| `QrGenerator` | 95% — URL encoding, size, error correction |
| `StripRendererService` | 90% — 3-photo composition, templates |
| `BookRepository` | 80% — CRUD, status transitions |
| `RevenueCatService` | 70% — purchase flow mocking |

### 9.2 Widget Tests
| Screen | Key Scenarios |
|--------|---------------|
| `BookBuilderScreen` | Template selection updates preview; cover edits persist; generate button disabled while loading |
| `BookPreviewScreen` | Flip animation; QR tap opens player; unlock button shows price; purchase success → unlocked state |
| `StripBuilderScreen` | Drag-reorder photos; template change updates canvas; caption saves; download produces PNG |

### 9.3 Integration Tests (flutter_driver / integration_test)
1. **Full book generation**: Create album → add memories (photo, video, voice, notes) → end trip → generate book → preview → unlock → download PDF
2. **Print flow**: Unlocked book → order print → webview checkout → webhook confirms → tracking appears
3. **Photobooth**: Generate strips → add to book → regenerate book includes strips

### 9.4 Golden Tests
- PDF page renderings for each template (compare against approved PNGs)
- Flipbook frame snapshots
- Strip template outputs

---

## 10. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| PDF generation too slow on device (>10s) | Medium | High | Profile early; use `compute()` isolate; offer server-side generation for >100pp |
| Peecho API changes / rate limits | Low | High | Abstract behind `PrintPartnerApi` interface; support multiple partners (Blurb, Lulu) |
| QR code signed URLs expire (7 days) | High | Medium | Edge Function cron to refresh; fallback to "open in app" deep link without expiry |
| Apple rejects IAP for "digital content unlock" | Low | High | Use "consumable" for book unlock; clearly digital; appeal path ready |
| Memory pressure on large albums (200+ photos) | Medium | High | Chunked PDF generation; downsample images to 300 DPI max; stream to storage |
| Photobooth strip auto-grouping feels wrong | Medium | Medium | Manual override always available; smart grouping = suggestion only |
| Print color mismatch (screen vs paper) | Medium | Medium | Provide "Print Preview" with CMYK simulation; order 1 proof copy first |

---

## 11. Success Metrics

| Metric | Phase 1A Target | Phase 1B Target | Phase 1C Target |
|--------|-----------------|-----------------|-----------------|
| Book generation rate (ended albums) | ≥15% | ≥20% | ≥25% |
| Digital unlock conversion | ≥5% | ≥8% | ≥10% |
| Strip add-on attachment | — | ≥20% of books | ≥25% of books |
| Print order rate (of unlocked) | — | — | ≥3% |
| Avg. revenue per ended album | $0.20 | $0.50 | $1.50 |
| PDF generation time (P95) | <5s | <5s | <8s (print-ready) |
| Crash-free sessions | 99.9% | 99.9% | 99.9% |

---

## 12. Open Questions (Resolve Before Implementation)

1. **Template customization depth**: Allow users to tweak fonts/colors per template, or keep templates fixed? → *Recommendation: Fixed templates for v1; "My Style" preset in v2*
2. **Video in print**: QR only, or also extract keyframe as still? → *Keyframe as still + QR for v1*
3. **Collaborative editing**: Can multiple members edit cover/title? → *Creator only for v1; "Suggest edit" for members in v2*
4. **Offline support**: Cache generated PDF for offline viewing? → *Yes, download button stores in app documents directory*
5. **GDPR/CCPA**: QR URLs contain memory IDs — PII risk? → *Use opaque tokens, not raw IDs; tokens expire*
6. **Right-to-left languages**: Template layouts support RTL? → *Design templates RTL-aware; flip grid order for Arabic/Hebrew*

---

## 13. Approval & Next Steps

**Design Review Checklist:**
- [ ] Product scope aligns with ReLog2 vision
- [ ] Technical approach fits existing architecture
- [ ] Data models extend (not break) current schema
- [ ] Commerce model sustainable
- [ ] Risks acknowledged with mitigations
- [ ] Open questions flagged for resolution

**Next Step:** Upon approval → Invoke `writing-plans` skill to create detailed implementation plan with task breakdown, file paths, and verification steps.

---

*Document location: `docs/superpowers/specs/2026-07-17-custom-memory-book-design.md`*