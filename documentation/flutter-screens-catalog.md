# OmniLuxe Store — Flutter Mobile App Screens Catalog & Architecture

> **Application**: OmniLuxe Store Consumer Mobile App (`apps/mobile-pos`)  
> **Target Framework**: Flutter 3.27+ / Dart 3.6+  
> **State Management**: Flutter Riverpod (`StateNotifierProvider`)  
> **Local Persistence**: SQLite (`sqflite`) for offline catalog caching and order history  
> **Design Theme**: Editorial Light Luxury (Ivory `#FBFBF9`, Warm Cream `#F4F2EB`, Forest Green `#233C32`, Deep Ink `#242B27`, Hairline `#E3E5DF`, Sage `#7B846D`, Champagne Gold `#C29B38`)  
> **Retail Profile**: High-End Multi-Department Lifestyle & Fashion Retail Store (Women, Men, Kids, Footwear, Beauty & Fragrance, Tech)  
> **Push Notifications**: Firebase Cloud Messaging (FCM) + In-App Unread Alerts Center  
> **Authentication Modes**: Guest Explorer Mode (Instant browse & checkout) + Multi-Step VIP Onboarding  
> **Cart Terminology**: Standardized to **Cart** across all consumer touchpoints  
> **Document Version**: 3.0.0  

---

## 1. Application Screen Hierarchy & Navigation Flow

The mobile app implements a clean, nested navigation hierarchy centered around an animated splash launcher, guest explorer capabilities, multi-step customer authentication, a persistent 5-tab customer experience, and dedicated customer care screens:

```mermaid
flowchart TD
    Splash["1. SplashScreen\n(screens/splash/splash_screen.dart)\nAnimated Gold Monogram & Sync"]

    MainShell["2. StoreMainScreen\n(screens/store/store_main_screen.dart)\n5-Tab Bottom Navigation Shell"]

    Splash -->|Auto Transition (2.4s)| MainShell

    subgraph TabNavigation["5 Core Customer Tabs (Light Editorial)"]
        Tab1["3. StoreHomeScreen\n(screens/store/store_home_screen.dart)\nHero Lookbook • Brands • Departments"]
        Tab2["4. StoreCatalogScreen (Explore)\n(screens/store/store_catalog_screen.dart)\nSearch • Filter Chips • Grid"]
        Tab3["5. StoreCartScreen (Cart)\n(screens/store/store_cart_screen.dart)\nCart Steppers • Summary • Subtotal"]
        Tab4["6. StoreOrdersScreen (Orders)\n(screens/store/store_orders_screen.dart)\nOrder Ledger • Status Badges"]
        Tab5["7. StoreMemberScreen (VIP Club & Guest Mode)\n(screens/store/store_member_screen.dart)\nGuest Overview • Digital Privilege Card"]
    end

    MainShell --> Tab1
    MainShell --> Tab2
    MainShell --> Tab3
    MainShell --> Tab4
    MainShell --> Tab5

    subgraph CustomerCareAndPush["Customer Care, Notifications & Settings"]
        NotifScreen["8. StoreNotificationsScreen\n(screens/store/store_notifications_screen.dart)\nFirebase FCM Push History & Unread Filter"]
        ProfileScreen["9. StoreProfileScreen\n(screens/store/store_profile_screen.dart)\nProfile, Verified Mobile & Notification Toggles"]
        MoreScreen["10. StoreMoreScreen\n(screens/store/store_more_screen.dart)\nBoutique Locator, Warranty & Customer Concierge"]
    end

    Tab1 -.->|Bell Icon| NotifScreen
    Tab1 -.->|Menu Icon| MoreScreen
    Tab5 -.->|Gear Icon| ProfileScreen
    Tab5 -.->|Bell Icon| NotifScreen
    MoreScreen -.->|Profile Link| ProfileScreen
    MoreScreen -.->|Push Alerts| NotifScreen

    subgraph AuthAndGuest["Guest Mode & Multi-Step Authentication"]
        AuthSteps["11. StoreAuthStepsScreen\n(screens/store/store_auth_steps_screen.dart)\nStep 1: Contact / Guest Option\nStep 2: Password & VIP Enrollment\nStep 3: Privilege Card Issued"]
    end

    Tab5 -.->|Tap Sign In / Register| AuthSteps
    Tab3 -.->|Guest Mode or Sign In| AuthSteps
    ProfileScreen -.->|Sign In Prompt| AuthSteps

    subgraph DetailAndCheckout["Detail & Checkout Modals"]
        Detail["12. ProductDetailScreen\n(screens/store/product_detail_screen.dart)\nGallery • Specs • Warranty • Add to Cart"]
        Checkout["13. StoreCheckoutScreen\n(screens/store/store_checkout_screen.dart)\nGuest Checkout • Delivery • Payment"]
        OrderConfirm["14. OrderConfirmationScreen\n(screens/store/order_confirmation_screen.dart)\nAnimated Check • SMS Link • Receipt URL"]
        Receipt["15. ReceiptScreen\n(screens/receipt/receipt_screen.dart)\nThermal Receipt Slip & Warranty Details"]
    end

    Tab1 -.->|Tap Curated Item| Detail
    Tab2 -.->|Tap Product Card| Detail
    Detail -.->|Add to Cart| Tab3
    Tab3 -.->|Proceed to Checkout| Checkout
    Checkout -.->|Place Order (Guest or Member)| OrderConfirm
    OrderConfirm -.->|View Receipt| Receipt
    Tab4 -.->|Tap Order| Receipt

    subgraph StaffAndSettings["In-Store Staff Operational Counter Layer (Dedicated Desktop POS Only)"]
        Settings["16. SettingsScreen\n(Hardware config & ESC/POS pairing)"]
        Pairing["17. PairingScreen\n(Counter register UUID)"]
        StaffLogin["18. LoginScreen\n(Cashier PIN 1234)"]
        StaffPOS["19. PosScreen\n(Desktop counter terminal)"]
        CashSession["20. CashSessionDialog\n(Shift opening & X/Z reports)"]
        BarcodeScanner["21. BarcodeScannerDialog\n(High-speed barcode scanner)"]
        PaymentDialog["22. PaymentDialog\n(Cashier tender settlement)"]
    end

    StaffLogin -.->|Auth Success| StaffPOS
    StaffPOS -.->|Shift Management| CashSession
    StaffPOS -.->|Hardware Wedge| BarcodeScanner
    StaffPOS -.->|Tender Settlement| PaymentDialog
    Settings -.->|Device UUID| Pairing
```

---

## 2. Complete Screen Catalog Inventory

### Screen 1: Splash Screen
- **Class & File**: [`SplashScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/splash/splash_screen.dart) in `lib/screens/splash/splash_screen.dart`
- **Design Theme**: Clean ivory canvas (`#FBFBF9`), signature forest green medallion with champagne gold monogram `O`, and deep ink typography.
- **Key UI Components**:
  - Pulsing medallion with monogram `O`.
  - Elegant serif title `OMNILUXE STORE` with letter-spacing `4.0`.
  - Subtitle badge: `COLOMBO 03 FLAGSHIP • SYNCED WITH CENTRAL OMNILUXE ERP`.
  - Forest green progress indicator.
- **State Management**: Listens to `syncProvider` to ensure catalog checkpoint is ready.
- **Actions**: Auto-advances to `StoreMainScreen` after 2400ms duration.

---

### Screen 2: Flagship Main Shell (5-Tab Container)
- **Class & File**: [`StoreMainScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/store_main_screen.dart) in `lib/screens/store/store_main_screen.dart`
- **Design Theme**: Clean white paper bottom bar (`#FFFFFF`) with `#E3E5DF` hairline border, deep forest green active indicator, and sage inactive icons.
- **5 Navigation Items**:
  1. `Home` (`Icons.home_outlined` / `Icons.home`)
  2. `Explore` (`Icons.explore_outlined` / `Icons.explore`)
  3. `Cart` (`Icons.shopping_cart_outlined` / `Icons.shopping_cart` + dynamic badge count)
  4. `Orders` (`Icons.receipt_long_outlined` / `Icons.receipt_long`)
  5. `VIP Club` (`Icons.card_membership_outlined` / `Icons.card_membership`)

---

### Screen 3: Home Lookbook Screen
- **Class & File**: [`StoreHomeScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/store_home_screen.dart) in `lib/screens/store/store_home_screen.dart`
- **Key UI Components**:
  - Top AppBar with:
    - Notification Bell with unread badge counter (`unreadNotificationCountProvider`).
    - Shopping Cart shortcut.
    - More & Services menu button.
  - Hero Lookbook Banner in Deep Forest Green (`#233C32`) with gold tag `FLAGSHIP SHOWCASE 2026`.
  - Tagline: `Apparel • Footwear • Beauty & Fragrance • Tech`.
  - Horizontal brand carousel: `Studio Ceylon`, `Ralph Lauren`, `Tommy Hilfiger`, `Calvin Klein`, `Nike`, `Zara`, `Dior`, `Apple`, `Adidas`.
  - 5 Department cards:
    - *Designer Fashion* (Studio Ceylon, Zara, Polo)
    - *Footwear & Leather* (Nike, Adidas, Clarks)
    - *Perfumes & Beauty* (Dior, Calvin Klein, Chanel)
    - *Kids & Teens* (Polo Kids, Toys & Apparel)
    - *Smartphones & Lifestyle Tech* (Apple, Samsung, Sony Audio)

---

### Screen 4: Store Catalog & Explore Screen
- **Class & File**: [`StoreCatalogScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/store_catalog_screen.dart) in `lib/screens/store/store_catalog_screen.dart`
- **Key UI Components**:
  - Search bar with live debounce.
  - Category filter chips (All Collections, Designer Fashion, Footwear, Perfumery, Kids, Tech).
  - Product cards on white paper with hairline borders, stock status, official warranty chip, and 1-tap `Add to Cart` button.

---

### Screen 5: Shopping Cart Screen
- **Class & File**: [`StoreCartScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/store_cart_screen.dart) in `lib/screens/store/store_cart_screen.dart`
- **Key UI Components**:
  - App bar titled `SHOPPING CART` with item counter and `Clear Shopping Cart` option.
  - Item tiles: thumbnail, product name, unit price, quantity steppers (`-`, qty, `+`), and delete icon.
  - Order summary card on warm cream (`#F4F2EB`): subtotal, white-glove packaging, grand total.
  - Primary button: `PROCEED TO SECURE CHECKOUT` in signature forest green.

---

### Screen 6: Customer Orders Ledger Screen
- **Class & File**: [`StoreOrdersScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/store_orders_screen.dart) in `lib/screens/store/store_orders_screen.dart`
- **Key UI Components**:
  - Order cards with invoice reference (e.g., `ORD-2026-XXXX`), timestamp, item summary, total amount, and payment status badge (`PAID`).
  - 1-tap navigation to view digital thermal receipt slip.

---

### Screen 7: VIP Club & Guest Mode Screen
- **Class & File**: [`StoreMemberScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/store_member_screen.dart) in `lib/screens/store/store_member_screen.dart`
- **Key UI Components**:
  - **Guest Mode State**: Guest Explorer card with quick explanation: "Browsing with instant checkout & SMS verification".
  - Quick CTA: `Sign In or Register with Steps (+100 Pts)` (opens `StoreAuthStepsScreen`).
  - Instant demo login button: `Instant Demo: Dulantha (VIP Gold Member)`.
  - **Member State**: Deep Forest Green Digital Privilege Card (`#233C32` gradient) with embossed gold monogram `O`, member tier (`GOLD VIP`), cardholder name, club loyalty points, and store credit limit.
  - Privileges breakdown card and Account Credentials card.

---

### Screen 8: Push Notifications Center Screen
- **Class & File**: [`StoreNotificationsScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/store_notifications_screen.dart) in `lib/screens/store/store_notifications_screen.dart`
- **Key UI Components**:
  - Firebase FCM active status indicator banner with unread counter.
  - Filter chips: `All Alerts`, `Orders`, `VIP Club`, `Promotions`.
  - Notification tiles with category icons, timestamp, unread indicator dot, and tap-to-read interaction.
  - Header action: `Mark All Read`.

---

### Screen 9: Customer Profile & Settings Screen
- **Class & File**: [`StoreProfileScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/store_profile_screen.dart) in `lib/screens/store/store_profile_screen.dart`
- **Key UI Components**:
  - Cardholder avatar and tier badge.
  - Verified mobile phone number for instant tamper-evident SMS receipts.
  - Saved delivery street addresses.
  - Push Notification toggles:
    - *FCM Order Status Alerts*
    - *VIP Collection Drops & Promos*
    - *Tamper-Evident SMS Receipts*
  - Sign Out action.

---

### Screen 10: More & Services Menu Screen
- **Class & File**: [`StoreMoreScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/store_more_screen.dart) in `lib/screens/store/store_more_screen.dart`
- **Key UI Components**:
  - Profile header card with direct link to `StoreProfileScreen`.
  - Customer Services group:
    - Push Notifications Center (with live unread badge).
    - Find a Boutique (Colombo 03 Flagship, Kandy City Centre, Galle Fort).
    - Warranty & 14-Day Exchange Policy dialog.
    - Customer Concierge & Support WhatsApp direct link.
  - Privilege & Policies group:
    - Privilege Club Tiers & Rewards (Silver, Gold, Platinum VIP benefits).
    - Customer Privacy & Data Protection (Phone masking, zero trackers, verified push delivery).
    - 100% Authenticity Guarantee (Direct brand distributor sourcing).

---

### Screen 11: Multi-Step Login & Registration Screen
- **Class & File**: [`StoreAuthStepsScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/store_auth_steps_screen.dart) in `lib/screens/store/store_auth_steps_screen.dart`
- **Features**:
  - Visual Step Progress Tracker: `1. Contact` -> `2. Security & VIP` -> `3. VIP Ready`.
  - Mode toggle: Register vs Sign In.
  - **Step 1**: Email / Mobile input + prominent **"Continue Exploring as Guest"** bypass button.
  - **Step 2**: Password, Full Name, and VIP Club Enrollment opt-in (+100 Welcome Points).
  - **Step 3**: Confirmation banner and instant digital loyalty card issuance.

---

### Screen 12: Product Detail Screen
- **Class & File**: [`ProductDetailScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/product_detail_screen.dart) in `lib/screens/store/product_detail_screen.dart`
- **Key UI Components**: Warm cream image gallery, brand tags, price, warranty badge, serial tracking indicators, sticky `Add to Cart` and `Buy Now` buttons.

---

### Screen 13: Secure Checkout Screen
- **Class & File**: [`StoreCheckoutScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/store_checkout_screen.dart) in `lib/screens/store/store_checkout_screen.dart`
- **Key UI Components**: Guest checkout banner, recipient details, fulfillment choice (Delivery vs Boutique Pickup), payment tender (Card vs Cash on Delivery), and forest green primary CTA button.

---

### Screen 14: Order Confirmation Screen
- **Class & File**: [`OrderConfirmationScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/store/order_confirmation_screen.dart) in `lib/screens/store/order_confirmation_screen.dart`
- **Key UI Components**: Animated checkmark, order reference number, verified SMS receipt dispatched notice, and direct link to web receipt.

---

### In-Store Operational & Cashier Modules (Isolated from Consumer Journeys)
> **Security & Zero-Leakage Policy**: The following operational screens are isolated strictly for in-store staff counter devices (`apps/windows-pos`) and are **completely invisible and inaccessible** from the consumer shopping mobile application:
- [`ReceiptScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/receipt/receipt_screen.dart): Thermal receipt preview and print sharing.
- [`SettingsScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/settings/settings_screen.dart): Hardware config, ESC/POS printer pairing, cash drawer pulse commands.
- [`PairingScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/auth/pairing_screen.dart): Counter register UUID registration (`COUNTER-01`).
- [`LoginScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/auth/login_screen.dart): Cashier numeric PIN login (`1234`).
- [`PosScreen`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/pos/pos_screen.dart): Desktop/tablet high-throughput cashier counter POS.
- [`CashSessionDialog`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/session/cash_session_dialog.dart): Shift opening/closing, float entry, and X/Z reports.
- [`BarcodeScannerDialog`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/scanner/barcode_scanner_dialog.dart): Hardware scanner listener & camera wedge.
- [`PaymentDialog`](file:///Users/chanaka/Desktop/projects/pos/apps/mobile-pos/lib/screens/checkout/payment_dialog.dart): Split-tender multi-currency cashier finalization.
