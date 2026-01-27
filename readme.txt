=== Simple Block Animations ===
Contributors: valentingrenier
Tags: gutenberg, blocks, animation, scroll, effects
Requires at least: 5.8
Tested up to: 6.9
Requires PHP: 7.4
Stable tag: 1.0.1
License: GPLv2 or later
License URI: https://www.gnu.org/licenses/gpl-2.0.html

Add beautiful scroll-triggered animations to any Gutenberg block with a simple, lightweight solution.

== Description ==

Simple block animations adds scroll-triggered animations to WordPress Gutenberg blocks without any coding required.

**Features:**

* 5 animation types (fade, slide up/down/left/right)
* Customizable duration and delay
* Works with all blocks (core, third-party, and custom blocks)
* Lightweight (CSS + Intersection Observer)
* No jQuery or heavy libraries
* Accessibility-friendly (respects prefers-reduced-motion)

**Supported Blocks:**

Works with all WordPress blocks, including core blocks, third-party blocks, and custom blocks.

**Development:**

The source code for this plugin is available on GitHub: https://github.com/valentin-grenier/simple-animations-for-gutenberg

The plugin uses npm and webpack to compile JavaScript and CSS files. Source files are located in the `src/` directory, and compiled files are in the `build/` directory.

To build from source:
1. Install dependencies: `npm install`
2. Build for production: `npm run build`
3. Build for development: `npm run dev`

== Installation ==

1. Upload the plugin files to `/wp-content/plugins/simple-block-animations/`
2. Activate the plugin through the 'Plugins' screen in WordPress
3. Select any block in Gutenberg
4. Open the block settings panel
5. Find the "Animations" section
6. Enable animation and customize

== Frequently Asked Questions ==

= Does it work with any theme? =

Yes! The plugin works with any WordPress theme that supports Gutenberg.

= Does it slow down my site? =

No. The plugin uses native CSS animations and Intersection Observer API. Assets only load on pages with animated blocks.

= Can I use it with page builders? =

It's designed for Gutenberg blocks. It won't work with Elementor, Divi, or other page builders.

== Screenshots ==

1. Animation controls in the block inspector
2. Animation type selector
3. Duration and delay controls
4. Example of fade-in animation

== Changelog ==

= 1.0.0 =
* Initial release
* 5 animation types
* Duration and delay controls
* Support for core and Meta Box blocks

== Upgrade Notice ==

= 1.0.0 =
Initial release.