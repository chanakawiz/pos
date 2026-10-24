# OmniLuxe Store — Flutter Mobile App Screens Catalog & Architecture

> **Application**: OmniLuxe Store Consumer Mobile App (`apps/mobile-pos`)  
> **Target Framework**: Flutter 3.27+ / Dart 3.6+  
> **State Management**: Flutter Riverpod (`StateNotifierProvider`)  
> **Local Persistence**: SQLite (`sqflite`) for offline catalog caching and order history  
> **Design Theme**: Editorial Light Luxury (Ivory `#FBFBF9`, Warm Cream `#F4F2EB`, Forest Green `#233C32`, Deep Ink `#242B27`, Hairline `#E3E5DF`, Sage `#7B846D`, Champagne Gold `#C29B38`)  
> **Authentication Modes**: Guest Mode (Instant browse & checkout) + Multi-Step VIP Onboarding  
> **Cart Terminology**: Standardized to **Cart** across all customer touchpoints  
> **Document Version**: 2.0.0  

---

## 1. Application Screen Hierarchy & Navigation Flow

The mobile app implements a clean, nested navigation hierarchy centered around an animated splash launcher, guest explorer capabilities, multi-step customer authentication, and a persistent 5-tab customer experience:

```mermaid
flowchart TD
    Splash["1. SplashScreen\n(screens/splash/splash_screen.dart)\nAnimated Gold Monogram & Sync"]

    MainShell["2. StoreMainScreen\n(screens/store/store_main_screen.dart)\n5-Tab Bottom Navigation Shell"]

    Splash -->|Auto Transition (2.4s)| MainShell

    subgraph TabNavigation["5 Core Customer Tabs (Light Editorial)"]
        Tab1["3. StoreHomeScreen\n(screens/store/store_home_screen.dart)\nHero Lookbook • Brands • Departments"]
        Tab2["4. StoreCatalogScreen (Explore)\n(screens/store/store_catalog_screen.dart)\nSearch • Filter Chips • Grid"]
        Tab3["5. StoreCartScreen (Cart)\n(screens/store/store_cart_screen.dart)\nCart Steppers • Promo • Subtotal"]
        Tab4["6. StoreOrdersScreen (Orders)\n(screens/store/store_orders_screen.dart)\nOrder Ledger • Status Badges"]
        Tab5["7. StoreMemberScreen (VIP Club & Guest Mode)\n(screens/store/store_member_screen.dart)\nGuest Overview • Digital Privilege Card"]
    end

    MainShell --> Tab1
    MainShell --> Tab2
    MainShell --> Tab3
    MainShell --> Tab4
    MainShell --> Tab5

    subgraph AuthAndGuest["Guest Mode & Multi-Step Authentication"]
        AuthSteps["8. StoreAuthStepsScreen\n(screens/store/store_auth_steps_screen.dart)\nStep 1: Contact / Guest Option\nStep 2: Password & VIP Enrollment\nStep 3: Privilege Card Issued"]
    end

    Tab5 -.->|Tap Sign In / Register| AuthSteps
    Tab3 -.->|Guest Mode or Sign In| AuthSteps

    subgraph DetailAndCheckout["Detail & Checkout Modals"]
        Detail["9. ProductDetailScreen\n(screens/store/product_detail_screen.dart)\nGallery • Specs • Warranty • Add to Cart"]
        Checkout["10. StoreCheckoutScreen\n(screens/store/store_checkout_screen.dart)\nGuest Checkout • Delivery • Payment"]
        OrderConfirm["11. OrderConfirmationScreen\n(screens/store/order_confirmation_screen.dart)\nAnimated Check • SMS Link • Receipt URL"]
        Receipt["12. ReceiptScreen\n(screens/receipt/receipt_screen.dart)\nThermal Receipt Slip & Warranty Details"]
    end

    Tab1 -.->|Tap Curated Item| Detail
    Tab2 -.->|Tap Product Card| Detail
    Detail -.->|Add to Cart| Tab3
    Tab3 -.->|Proceed to Checkout| Checkout
    Checkout -.->|Place Order (Guest or Member)| OrderConfirm
    OrderConfirm -.->|View Receipt| Receipt
    Tab4 -.->|Tap Order| Receipt

    subgraph StaffAndSettings["Staff & Hardware Operational Screens"]
        Settings["13. SettingsScreen\n(screens/settings/settings_screen.dart)"]
        Pairing["14. PairingScreen\n(screens/auth/pairing_screen.dart)"]
        StaffLogin["15. LoginScreen\n(screens/auth/login_screen.dart)"]
        StaffPOS["16. PosScreen\n(screens/pos/pos_screen.dart)"]
        CashSession["17. CashSessionDialog\n(screens/session/cash_session_dialog.dart)"]
        BarcodeScanner["18. BarcodeScannerDialog\n(screens/scanner/barcode_scanner_dialog.dart)"]
        PaymentDialog["19. PaymentDialog\n(screens/checkout/payment_dialog.dart)"]
    end

    Tab5 -.->|Gear Icon| Settings
    Settings -.->|Device UUID| Pairing
    Settings -.->|Staff Portal| StaffLogin
    StaffLogin -.->|Auth Success| StaffPOS
    StaffPOS -.->|Shift Management| CashSession
    StaffPOS -.->|Camera Scanner| BarcodeScanner
    StaffPOS -.->|Charge Bill| PaymentDialog
```

---

## 2. Complete Screen Catalog Inventory

### Screen 1: Splash Screen
- **Class & File**: [`SplashScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/splash/splash_screen.dart) in `lib/screens/splash/splash_screen.dart`
- **Route / Access**: Application initial route (`/`)
- **Primary Persona**: All users (Shoppers, VIP members, and staff)
- **Design Theme**: Clean ivory canvas (`#FBFBF9`), signature forest green medallion with champagne gold monogram `O`, and deep ink typography.
- **Key UI Components**:
  - Pulsing medallion with monogram `O`.
  - Elegant serif title `OMNILUXE STORE` with letter-spacing `4.0`.
  - Subtitle badge: `COLOMBO 03 FLAGSHIP • SYNCED WITH CENTRAL OMNILUXE ERP`.
  - Forest green progress indicator.
- **State Management**: Listens to `syncProvider` to ensure catalog checkpoint is ready.
- **API & Storage Integration**: Pulls initial delta from `GET /api/v1/products` into local SQLite.
- **Actions**: Auto-advances to `StoreMainScreen` after 2400ms duration.

---

### Screen 2: Flagship Main Shell (5-Tab Container)
- **Class & File**: [`StoreMainScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/store_main_screen.dart) in `lib/screens/store/store_main_screen.dart`
- **Route / Access**: Root navigation shell
- **Primary Persona**: Online shopper
- **Design Theme**: Clean white paper bottom bar (`#FFFFFF`) with `#E3E5DF` hairline border, deep forest green active indicator, and sage inactive icons.
- **Key UI Components**:
  - Custom `IndexedStack` preserving scroll states across tabs.
  - 5 Navigation items with forest green active tint:
    1. `Home` (`Icons.home_outlined` / `Icons.home`)
    2. `Explore` (`Icons.explore_outlined` / `Icons.explore`)
    3. `Cart` (`Icons.shopping_cart_outlined` / `Icons.shopping_cart` + dynamic badge count)
    4. `Orders` (`Icons.receipt_long_outlined` / `Icons.receipt_long`)
    5. `VIP Club` (`Icons.card_membership_outlined` / `Icons.card_membership`)

---

### Screen 3: Home Lookbook Screen
- **Class & File**: [`StoreHomeScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/store_home_screen.dart) in `lib/screens/store/store_home_screen.dart`
- **Route / Access**: Bottom Navigation Tab 0 (`Home`)
- **Key UI Components**:
  - Clean white app bar with title `OMNILUXE STORE`, Colombo 03 Flagship subtitle, and quick cart shortcut button.
  - Hero Lookbook Banner in Deep Forest Green (`#233C32`) with gold tag `FLAGSHIP SHOWCASE 2026`.
  - Horizontal brand carousel: `Apple`, `Nike`, `Toyota`, `Studio Ceylon`, `Zara`.
  - 4 Department cards on ivory canvas:
    - *Smartphones & Tech* (Apple, Samsung, Sony)
    - *Designer Fashion* (Studio Ceylon, Zara)
    - *Footwear & Sneakers* (Nike, Adidas, Clarks)
    - *Luxury Automobili* (Toyota, Defender, BYD)

---

### Screen 4: Store Catalog & Explore Screen
- **Class & File**: [`StoreCatalogScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/store_catalog_screen.dart) in `lib/screens/store/store_catalog_screen.dart`
- **Route / Access**: Bottom Navigation Tab 1 (`Explore`)
- **Key UI Components**:
  - Search input with live debounce.
  - Filter chips for all categories.
  - Grid of product cards with stock status badge, serial tracking indicator, warranty chip, and 1-tap `Add to Cart` button.

---

### Screen 5: Shopping Cart Screen
- **Class & File**: [`StoreCartScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/store_cart_screen.dart) in `lib/screens/store/store_cart_screen.dart`
- **Route / Access**: Bottom Navigation Tab 2 (`Cart`)
- **Terminology**: Exclusively **Cart** (replaced all occurrences of "bag").
- **Key UI Components**:
  - App bar titled `SHOPPING CART` with item count and `Clear Shopping Cart` option.
  - Cart item cards on white paper: thumbnail, name, unit price, quantity steppers (`-`, count, `+`), and delete icon.
  - Order summary card on warm cream (`#F4F2EB`): subtotal, complimentary white-glove packaging, grand total.
  - Primary button: `PROCEED TO SECURE CHECKOUT` in signature forest green.

---

### Screen 6: Customer Orders Ledger Screen
- **Class & File**: [`StoreOrdersScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/store_orders_screen.dart) in `lib/screens/store/store_orders_screen.dart`
- **Route / Access**: Bottom Navigation Tab 3 (`Orders`)
- **Key UI Components**:
  - Order cards with invoice reference (e.g., `ORD-2026-XXXX`), timestamp, item summary, total amount, and payment status badge (`PAID`).
  - 1-tap navigation to view digital receipt slip.

---

### Screen 7: VIP Club & Guest Mode Screen
- **Class & File**: [`StoreMemberScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/store_member_screen.dart) in `lib/screens/store/store_member_screen.dart`
- **Route / Access**: Bottom Navigation Tab 4 (`VIP Club`)
- **Key UI Components**:
  - **Guest Mode State (Unauthenticated)**:
    - Guest Explorer card with quick explanation: "Browsing with instant checkout & SMS verification".
    - Primary CTA: `Sign In or Register with Steps (+100 Pts)` (opens `StoreAuthStepsScreen`).
    - One-tap demo button: `Instant Demo: Dulantha (VIP Gold Member)`.
    - Overview of VIP perks (100 welcome points, SMS warranty receipts, omnichannel credit).
  - **Member State (Authenticated)**:
    - Prestigious Deep Forest Green Digital Privilege Card (`#233C32` gradient) with embossed gold monogram `O`, member tier (`GOLD VIP`), cardholder name, club loyalty points, and store credit limit.
    - VIP privileges breakdown (point cash value, official warranty status).
    - Account credentials card (name, email, phone, omnichannel status).
    - Sign Out button in app bar.

---

### Screen 8: Multi-Step Login & Registration Screen
- **Class & File**: [`StoreAuthStepsScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/store_auth_steps_screen.dart) in `lib/screens/store/store_auth_steps_screen.dart`
- **Route / Access**: Triggered from VIP tab or Cart checkout prompt
- **Features**:
  - Visual Step Progress Tracker: `1. Contact` -> `2. Security & VIP` -> `3. VIP Ready`.
  - Mode toggle: Register vs Sign In.
  - **Step 1**: Email / Mobile input + prominent **"Continue Exploring as Guest"** bypass button.
  - **Step 2**: Password, Full Name, and VIP Club Enrollment opt-in (+100 Welcome Points).
  - **Step 3**: Confirmation banner and instant digital loyalty card issuance.

---

### Screen 9: Product Detail Screen
- **Class & File**: [`ProductDetailScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/product_detail_screen.dart) in `lib/screens/store/product_detail_screen.dart`
- **Key UI Components**:
  - Warm cream image gallery with interactive image viewer.
  - Brand and category tags, price, warranty badge, and IMEI tracking indicators.
  - Sticky bottom action bar with `Add to Cart` and `Buy Now` buttons.

---

### Screen 10: Secure Checkout Screen
- **Class & File**: [`StoreCheckoutScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/store_checkout_screen.dart) in `lib/screens/store/store_checkout_screen.dart`
- **Key UI Components**:
  - **Guest Checkout Banner**: Highlights that orders can be completed as a guest without mandatory login.
  - Form sections:
    1. Recipient Information (Full Name, Phone for SMS bill, Email)
    2. Fulfillment Method (Express Courier Delivery vs Flagship Pickup)
    3. Payment Method (Card vs Cash on Delivery)
    4. Order breakdown summary
  - Primary CTA: `CONFIRM & PLACE ORDER` in signature forest green with white text.

---

### Screen 11: Order Confirmation Screen
- **Class & File**: [`OrderConfirmationScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/order_confirmation_screen.dart) in `lib/screens/store/order_confirmation_screen.dart`
- **Key UI Components**:
  - Animated green checkmark badge.
  - Order reference number and customer greeting.
  - Verified SMS E-Receipt notice card with clickable/copyable URL to web receipt (`/receipt/{orderNumber}`).
  - Order metadata card and items breakdown.

---

### Screens 12 to 19: Hardware & POS Screens
- [`ReceiptScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/receipt/receipt_screen.dart): Thermal receipt preview and share.
- [`SettingsScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/settings/settings_screen.dart): Hardware config, ESC/POS printer pairing.
- [`PairingScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/auth/pairing_screen.dart): Device UUID registration.
- [`LoginScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/auth/login_screen.dart): Staff cashier login with PIN.
- [`PosScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/pos/pos_screen.dart): Desktop/tablet high-throughput cashier POS.
- [`CashSessionDialog`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/session/cash_session_dialog.dart): Shift opening/closing and X/Z reports.
- [`BarcodeScannerDialog`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/scanner/barcode_scanner_dialog.dart): Camera barcode & QR scanner.
- [`PaymentDialog`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/checkout/payment_dialog.dart): Cashier split tender and cash calculation.
