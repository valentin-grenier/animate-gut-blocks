# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

Simple Block Animations — a lightweight WordPress plugin that adds scroll-triggered
animations (fade, slide up/down/left/right) to any Gutenberg block. It does not
register its own blocks; it extends existing blocks with animation attributes from
the block editor. The frontend triggers CSS animations via `IntersectionObserver`
and respects `prefers-reduced-motion`.

- WordPress.org slug / text domain: `simple-block-animations`
- Published on the WordPress.org plugin directory.

## Architecture

PHP runtime (`includes/`, prefix `SIMPBLAN_` / `simpblan_`):
- `simple-block-animations.php` — bootstrap: defines `SIMPBLAN_VERSION` and paths,
  requires the classes, wires `plugins_loaded` + activation/deactivation hooks.
- `includes/class-enqueue.php` (`SIMPBLAN_Enqueue`) — enqueues the editor assets and
  *registers* the frontend ones from `build/`. The frontend assets are enqueued on
  demand by `SIMPBLAN_Blocks` when an animated block actually renders, so dynamic
  blocks, block templates, template parts and synced patterns are all covered. The
  initial hidden state is printed inline in `wp_head` (behind an `html.simpblan-js`
  class) so the late stylesheet cannot cause a flash, and content stays visible
  without JavaScript.
- `includes/class-blocks.php` (`SIMPBLAN_Blocks`) — on `render_block`, adds the
  animation class, custom properties and `data-animation` via `WP_HTML_Tag_Processor`
  (hence `Requires at least: 6.2`). `get_animation_types()` is the whitelist of
  supported types. Editor-side attributes are added by `src/js/editor.js`, which
  honours defaults declared in a block's own `block.json`.
- `includes/class-settings.php` (`SIMPBLAN_Settings`) — options (`default_duration`,
  `default_delay`).

JS/CSS — source in `src/`, compiled to `build/` with `@wordpress/scripts` (webpack
entries declared in `webpack.config.js`):
- `src/js/editor.js` → block inspector controls (type / duration / delay).
- `src/js/frontend.js` → `IntersectionObserver` trigger.
- `src/scss/editor.scss`, `src/scss/frontend.scss` → styles.

`build/` is gitignored and **not committed** — it is generated in CI at deploy time.

## Commands

- `npm install` — install deps (no committed lockfile, so `npm ci` will not work).
- `npm run build` — production build to `build/`.
- `npm run dev` — watch/dev build.
- `npm run lint:js` / `npm run lint:css` / `npm run format` — JS/CSS lint & format.
- `composer phpcs` / `composer phpcbf` — PHP coding standards (WPCS).

## Releasing to WordPress.org

Deployment is automated through GitHub Actions — **do not run the SVN deploy by hand**.

Primary path (one click): Actions tab → **"Release (bump + deploy)"** → Run workflow →
choose `patch` / `minor` / `major` / `custom`, with a changelog whose bullets are
separated by `|`. The workflow bumps the version everywhere, commits, tags, creates
the GitHub Release, builds, and deploys to the WordPress.org SVN via the 10up action.
The version logic lives in `bin/bump-version.sh <patch|minor|major|X.Y.Z> ["changelog"]`,
which is also runnable locally (it edits the files without deploying).

Secondary path: `.github/workflows/deploy.yml` deploys when a GitHub Release is
published manually in the UI — but it does **not** bump versions.

The version is stored in 4 places, kept in sync by the bump script:
- `simple-block-animations.php` — `Version:` header **and** `SIMPBLAN_VERSION` constant
- `readme.txt` — `Stable tag:`
- `package.json` — `version`

Gotchas:
- The release workflow does **not** touch `Tested up to:`. When a release claims a new
  WordPress compatibility, bump it manually in `readme.txt` **and**
  `simple-block-animations.php` before triggering the release.
- WordPress.org only serves an update when `readme.txt`'s `Stable tag` matches the
  release tag. Use plain numeric tags (`2.0.8`, no `v` prefix).
- `SVN_USERNAME` / `SVN_PASSWORD` are stored as repository secrets.
- `.distignore` decides what ships to SVN (keeps `build/`; excludes `src/`, `bin/`,
  `node_modules`, dev configs, docs).

## Conventions

- Commits: Conventional Commits in English (`feat:`, `fix:`, `chore:`, `ci:`),
  capitalised subject line.
