# SmartShop POS — UI Design & Wireframe Specifications

> **Document Version**: 1.0.0  
> **Aesthetic Standard**: Modern Glassmorphic Dark UI (Windows POS) & Clean Executive Light/Dark (Filament ERP)

---

## 1. Design System & Theme Tokens

### 1.1 Windows POS Color Palette
| Token | Hex Code | Purpose |
| :--- | :--- | :--- |
| **Background Deep** | `#020617` (Slate 950) | Main application backdrop |
| **Card & Panel Surface** | `#0f172a` (Slate 900) | Cart containers, modal cards, sidebars |
| **Panel Border** | `#1e293b` (Slate 800) | Subtle container definition |
| **Primary Accent** | `#4f46e5` (Indigo 600) | Navigation buttons, active states, badges |
| **Success / Checkout** | `#059669` (Emerald 600) | Pay button, cash drawer, active sync, discounts |
| **Warning / Hold** | `#d97706` (Amber 600) | Held bills, pending sync, low stock badges |
| **Danger / Discard** | `#e11d48` (Rose 600) | Item deletion, refunds, discrepancy alert |

### 1.2 Typography & Sizing
- **Main Font**: Inter / System UI sans-serif.
- **Monospace Font**: JetBrains Mono / Fira Code (Invoices, barcode, currency prices).
- **Scale**:
  - Grand Total: `text-3xl font-black font-mono`
  - Line Items: `text-sm font-semibold`
  - Badge / Status: `text-xs font-mono font-bold uppercase`

---

## 2. Windows POS Wireframes

### 2.1 Cashier Terminal Main Workspace
```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ [🛒 SMARTSHOP POS]  Downtown Store • Lane 01  [● Online] [F1 Help] [Shift: OPEN] [User] │
├───────────────────────────────────────────────────────────────┬────────────────────────┤
│ [Search barcode / product (Ctrl+F)] [All Categories ▼]        │ CURRENT CART (3 items) │
├───────────────────────────────────────────────────────────────┼────────────────────────┤
│ [All] [Beverages] [Bakery] [Produce] [Snacks] [Dairy] [Meat]  │ + Customer: Sarah M.   │
├───────────────────────────────────────────────────────────────┤ (150 Loyalty Pts)  [✕] │
│ ┌───────────────┐ ┌───────────────┐ ┌───────────────┐        │ ────────────────────── │
│ │ [Image]       │ │ [Image]       │ │ [Image]       │        │ 1. Organic Coffee 1kg  │
│ │ Roast Coffee  │ │ French Loaf   │ │ Almond Milk   │        │    2 x $22.50  $45.00  │
│ │ $22.50 [Stock]│ │ $3.50  [Stock]│ │ $4.20  [Stock]│        │    [- $2.50 Disc]  [🗑] │
│ └───────────────┘ └───────────────┘ └───────────────┘        │                        │
│ ┌───────────────┐ ┌───────────────┐ ┌───────────────┐        │ 2. French Baguette     │
│ │ [Image]       │ │ [Image]       │ │ [Image]       │        │    1 x $3.50    $3.50  │
│ │ Greek Yogurt  │ │ Honey Crisp   │ │ Green Tea Box │        │    [-] [1] [+]     [🗑] │
│ │ $5.80  [Stock]│ │ $2.10  [Stock]│ │ $6.40  [Stock]│        ├────────────────────────┤
│ └───────────────┘ └───────────────┘ └───────────────┘        │ Subtotal:       $48.50 │
│ ┌───────────────┐ ┌───────────────┐ ┌───────────────┐        │ Tax Amount:     $ 3.88 │
│ │ [Image]       │ │ [Image]       │ │ [Image]       │        │ Discounts:     -$ 2.50 │
│ │ Dark Chocolate│ │ Mineral Water │ │ Sea Salt Chips│        │ ────────────────────── │
│ │ $4.00  [Stock]│ │ $1.20  [Stock]│ │ $3.00  [Stock]│        │ GRAND TOTAL:   $ 49.88 │
│ └───────────────┘ └───────────────┘ └───────────────┘        │ [ Hold (F4) ] [Disc]   │
│                                                               │ [ PROCEED TO PAY (F9)] │
└───────────────────────────────────────────────────────────────┴────────────────────────┘
```

---

### 2.2 Multi-Lane Cloud Held Bills Modal
```text
┌────────────────────────────────────────────────────────────────────────┐
│ 🛒 Held Transactions (Multi-Lane Cloud Sync)                     [ ✕ ] │
├────────────────────────────────────────────────────────────────────────┤
│ Total 3 bills currently held across store checkout terminals.          │
│                                                                        │
│ ┌────────────────────────────────────────────────────────────────────┐ │
│ │ [HOLD-8821]  [☁ Multi-Lane]  14:22 PM                              │ │
│ │ Cashier: Sarah Miller • 4 items • Customer: David Kim              │ │
│ │                                              $ 62.50  [▶ Resume] [🗑]│
│ └────────────────────────────────────────────────────────────────────┘ │
│ ┌────────────────────────────────────────────────────────────────────┐ │
│ │ [HOLD-4419]  [☁ Multi-Lane]  14:31 PM                              │ │
│ │ Cashier: Alex Tan • 2 items • General Customer                     │ │
│ │                                              $ 18.00  [▶ Resume] [🗑]│
│ └────────────────────────────────────────────────────────────────────┘ │
│ ┌────────────────────────────────────────────────────────────────────┐ │
│ │ [HOLD-1002]  [Local Register]  14:35 PM                            │ │
│ │ Cashier: Self-Station • 1 item • Walk-in                           │ │
│ │                                              $  8.50  [▶ Resume] [🗑]│
│ └────────────────────────────────────────────────────────────────────┘ │
├────────────────────────────────────────────────────────────────────────┤
│ [ 🔄 Refresh Cloud Bills ]                                   [ Close ] │
└────────────────────────────────────────────────────────────────────────┘
```

---

### 2.3 Cashier Register Shift Modal (X-Report & Z-Report)
```text
┌────────────────────────────────────────────────────────────────────────┐
│ 🧾 Cash Register Session (Shift Audit)                           [ ✕ ] │
├────────────────────────────────────────────────────────────────────────┤
│ Store: Downtown Supercenter • Terminal: Lane 01                        │
│ Cashier: Sarah Miller • Opened At: 2026-09-27 08:30:00                 │
│ Status: [● ACTIVE SESSION]                                             │
│ ────────────────────────────────────────────────────────────────────── │
│ Opening Cash Float:                                           $ 150.00 │
│ + Cash Sales Collected (28 sales):                            $ 720.50 │
│ + Card / Digital Transactions (14 sales):                     $ 410.00 │
│ - Cash Refunds Paid Out (1 refund):                          -$  25.00 │
│ ────────────────────────────────────────────────────────────────────── │
│ EXPECTED CASH IN DRAWER:                                      $ 845.50 │
│ TOTAL REGISTER GROSS TURNOVER:                              $ 1,280.50 │
│ ────────────────────────────────────────────────────────────────────── │
│ Closing Cash Counted ($):  [ 845.50                                  ] │
│ Session Notes / Reason:    [ Shift completed cleanly                 ] │
├────────────────────────────────────────────────────────────────────────┤
│ [ 🖨️ Print Mid-Shift X-Report ]    [ 🔒 End Shift & Print Z-Report ]   │
└────────────────────────────────────────────────────────────────────────┘
```

---

### 2.4 Multi-Payment Finalization Modal
```text
┌────────────────────────────────────────────────────────────────────────┐
│ 💳 Finalize Transaction                                          [ ✕ ] │
├────────────────────────────────────────────────────────────────────────┤
│ Total Amount Due:                                             $ 49.88  │
│ ────────────────────────────────────────────────────────────────────── │
│ Select Payment Method:                                                 │
│ [ 💵 Cash (F1) ]   [ 💳 Card (F2) ]   [ 🏦 Bank Transfer ]             │
│                                                                        │
│ Cash Received ($):        [ 50.00                                   ]  │
│ Quick Denominations:      [ Exact ] [ $50 ] [ $60 ] [ $100 ]           │
│ ────────────────────────────────────────────────────────────────────── │
│ Change Due To Customer:                                       $  0.12  │
├────────────────────────────────────────────────────────────────────────┤
│ [ 🖨️ Print Receipt: ON ]           [ ✅ COMPLETE & KICK DRAWER (Enter) ]│
└────────────────────────────────────────────────────────────────────────┘
```

---

### 2.5 Flagship Thermal Receipt Wireframe
```text
┌────────────────────────────────────────────────────────┐
│ [ OmniLuxe Store Receipt Modal ]                   [✕] │
├────────────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────────────┐  │
│  │                 OMNILUXE STORE                   │  │
│  │           Colombo 03 Flagship Store              │  │
│  │        No. 124, Galle Road, Colombo 03           │  │
│  │            Tel: +94 11 234 5678                  │  │
│  │           Tax ID: VAT-9982412-000                │  │
│  │ ------------------------------------------------ │  │
│  │ Invoice:                         INV-20261024-01 │  │
│  │ Date:                        2026-10-24 17:30:12 │  │
│  │ Cashier:                             Sarah (1234)│  │
│  │ Customer:                 Dulantha (VIP Gold)    │  │
│  │ ------------------------------------------------ │  │
│  │ Item                              Qty      Total │  │
│  │ ------------------------------------------------ │  │
│  │ iPhone 15 Pro 128GB Titanium       1x     999.00 │  │
│  │  SN: 358291038472910                             │  │
│  │  Warranty: 1 Year Apple Care                     │  │
│  │ Nike Air Zoom Pegasus 40           1x     139.00 │  │
│  │  Size: UK 9 / Color: Obsidian                    │  │
│  │ ------------------------------------------------ │  │
│  │ Subtotal:                               $1,138.00│  │
│  │ VIP Member Discount:                    -$  50.00│  │
│  │ Tax (VAT):                              $   65.28│  │
│  │ TOTAL:                                  $1,153.28│  │
│  │ Paid (Visa Card):                       $1,153.28│  │
│  │ Change:                                 $    0.00│  │
│  │ ------------------------------------------------ │  │
│  │    Thank you for shopping at OmniLuxe Store!     │  │
│  │      Official Luxury Retail & ERP Network        │  │
│  │             ||| |||| |||||| |||||||              │  │
│  └──────────────────────────────────────────────────┘  │
├────────────────────────────────────────────────────────┤
│ [ 🖨️ Print Receipt (Enter) ]                  [ Close ]│
└────────────────────────────────────────────────────────┘
```

---

### 2.6 Hardware Barcode Scanner & Audio Wedge Architecture
```text
  [ USB / Bluetooth Handheld Barcode Scanner ]
                      │
   Keystroke Burst (<60ms interval + Enter)
                      ▼
  [ apps/windows-pos/src/hooks/useBarcodeScanner.ts ]
   (Universal wedge interceptor - works in any focus state)
                      │
            ┌─────────┴─────────┐
            ▼                   ▼
    [ Web Audio API ]    [ Product Catalog Lookup ]
  1760Hz Cashier Beep    1. Fast API: /api/v1/products/barcode/{code}
  (posSounds synthesizer) 2. Local Fallback: products.find(barcode)
                                │
                                ▼
                       [ Add Item to Cart ]
```

---

## 3. OmniLuxe Store Consumer Mobile App (Flutter)

### 3.1 Mobile Portrait — Flagship Home & Department Showcase
```text
┌──────────────────────────────────────┐
│ 17:30                     ● 5G [ 98%]│
│                                      │
│ OMNILUXE STORE                  [ 🛍️]│
│ Colombo 03 Flagship • Cloud Synced   │
├──────────────────────────────────────┤
│ ┌──────────────────────────────────┐ │
│ │ FLAGSHIP SHOWCASE 2026           │ │
│ │ Curated Luxury & Department      │ │
│ │ Collections                      │ │
│ │ Tech • Haute Couture • Footwear  │ │
│ └──────────────────────────────────┘ │
│                                      │
│ PREMIER BRANDS                       │
│ ( Apple ) ( Nike ) ( Toyota ) ( Zara)│
│                                      │
│ SHOP BY DEPARTMENT                   │
│ ┌────────────────┐ ┌───────────────┐ │
│ │ 📱 Smartphones │ │ 👗 Designer   │ │
│ │ Apple, Samsung │ │ Studio Ceylon │ │
│ └────────────────┘ └───────────────┘ │
│ ┌────────────────┐ ┌───────────────┐ │
│ │ 👟 Footwear    │ │ 🚘 Automobili │ │
│ │ Nike, Adidas   │ │ Toyota, BYD   │ │
│ └────────────────┘ └───────────────┘ │
├──────────────────────────────────────┤
│ [🏠 Home] [🧭 Explore] [🛍️ Bag]      │
│ [📜 Orders]           [👑 VIP Club]  │
└──────────────────────────────────────┘
```

### 3.2 Mobile Portrait — VIP Club Digital Privilege Card
```text
┌──────────────────────────────────────┐
│ 17:30                     ● 5G [ 98%]│
│                                      │
│ OMNILUXE VIP                     [ ⚙️]│
├──────────────────────────────────────┤
│ ┌──────────────────────────────────┐ │
│ │  (O) OMNILUXE PRIVILEGE          │ │
│ │                                  │ │
│ │  CARDHOLDER: Dulantha Perera     │ │
│ │  MEMBER ID:  VIP-9824-771        │ │
│ │                                  │ │
│ │  350 POINTS       [ GOLD VIP ]   │ │
│ │  Store Credit Limit: Rs. 500,000 │ │
│ └──────────────────────────────────┘ │
│                                      │
│ PRIVILEGE REWARDS                    │
│ • Redeem 350 pts for Rs. 3,500 off   │
│ • Complimentary Flagship Concierge   │
│ • Priority Allocation on New Drops   │
├──────────────────────────────────────┤
│ [🏠 Home] [🧭 Explore] [🛍️ Bag]      │
│ [📜 Orders]           [👑 VIP Club]  │
└──────────────────────────────────────┘
```
