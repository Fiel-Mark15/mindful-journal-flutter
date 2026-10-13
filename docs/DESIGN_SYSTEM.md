# Design system

Mindful Journal keeps the starter's restrained indigo identity. Warm near-white pages and dark ink replace tinted containers on every element. Writing and reading use typography and whitespace; a gradient is reserved for onboarding, check-in, and the center create action.

## Tokens

`AppColors`: ink/navy foundation (#20233F), indigo (#5856D6), violet (#7770EC), paper (#F8F8FC). Light secondary text is #626879. Dark surfaces are #14151F and #20222F with #F0EFF8 foreground, #BABCCD secondary text, and #ADA8FF accent. Scheme roles drive widget colors, including input errors and selected moods.

`AppLayout`: 24px page gutter, 720px maximum content width, 1000px sidebar breakpoint, 20px card radius. Spacing generally follows 4/8px increments. Buttons have at least 48px interactive height; primary actions start at 52px.

Typography uses system fonts: 34px large title, 28px editor title, 22px screen section, 17px entry/body, 14px metadata. Body line height is 1.6. Large text wraps; no app-level text-scale clamp.

`AppMotion` provides 170ms fast, 280ms normal and 440ms slow timings and zero-duration decorative animation when the platform disables animations. Native route/theme transitions remain framework managed. Selection and saving use brief haptic feedback where supported.

## Accessibility and layout

Moods combine Cupertino weather symbols, visible labels, and selected-state semantics. Icon-only actions have tooltips. Flutter buttons provide focus and keyboard activation. Mood choices wrap onto more rows at narrow widths or large text sizes; the editor scrolls when the keyboard appears. Desktop uses side navigation and a constrained reading/writing canvas.

Light and dark foreground/background token combinations were checked with a contrast calculation; normal text tokens exceed 4.5:1 against their intended surfaces. Mood selection uses matching onPrimaryContainer colors. This palette check is not a full screen-reader or WCAG audit. Native VoiceOver/TalkBack and physical-device haptic checks remain manual.

## Branding

The final approved folded-leaf emblem is the byte-exact 1254px RGB master at `assets/images/app_icon.png`. `flutter_launcher_icons` generates its native derivatives. `tools/generate_branding.py` uses this artwork without drawing or recoloring a replacement. The existing small branded launch image and navy launch background retain their layout, with no timed startup delay.

The four-destination phone navigation floats on a restrained surface with a raised 58px create control, animated selected tab capsule, press compression, spring return and a 45° plus rotation while its sheet is open. Profile uses a circular avatar and one balanced four-stat surface. The editor has an indigo cursor, subtle selection highlight, active formatting states, a focus-responsive toolbar fade/slide and a brief scaled Saved confirmation. Framework-managed modal, route and theme transitions are retained. Hero transitions, staggered entry animations, app-level text-size settings were intentionally omitted; system text scaling remains supported.

The global create action now has a 600ms, clipped, diagonal reflection triggered by touch activation or pointer hover. It never loops and respects reduced motion. Destination changes use a restrained fade. Appearance adds a disclosure row that opens preset gradient chips or a custom HSL picker, keeping the main Profile calm. Eight curated palettes preserve semantic contrasts in both brightness modes. Text colors are user-selected and adjusted to readable variants against their presentation surface; highlight is a subtle 22% tint.

Attachments appear only when present, using one large preview or an adaptive two-column grid. All media opens a pan/zoom viewer. Drawing uses a separate paper canvas with horizontally scrollable tools and accessible thickness choices. Photos, sketches, colors and themes all reset with the app process.

Calendar uses a Monday-first grid, visible day numbers, today/selection outlines, mood glyphs and softly linked writing days. Home gains one compact rhythm card between mood and creation. Search appears through an animated header; entry insertions/removals use 220ms fade/slide/size transitions. Checklists use a progressively painted tick, touch compression, muted completed text and haptics. Insights adds compact counts and simple mood bars without a chart package. Reduced-animation settings are respected.


## October 8 product experience pass

See [Product experience report](PRODUCT_EXPERIENCE_REPORT.md) for Today and memory logic, Prompt Packs, templates, collections, quick check-ins, writing preferences, Reflection Rings and wide Journal reading/editing panes. All additions are runtime-only; the existing single List of entries, media and rich formatting remain in place.
