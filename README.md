# Ruflo site workspace

This repository holds reusable agent profiles, their original sources and licenses, technical skills, version records, and site launch scripts. It does not contain a site template or client memory.

Run `npm ci` in this folder and `scripts/install-codex-tools.ps1` once for the Codex user account. `scripts/new-site.ps1` creates a blank sibling project with a new Git repository and `site_id`. To attach an existing site after moving it to this computer, run `scripts/register-site.ps1 -ProjectPath <path>`. `scripts/open-site.ps1` starts a fresh Codex session with the site's Ruflo memory database selected. Open an existing site from its own folder. Do not resume or fork a session from another site.

The local registry (`registry.local.json`) contains machine paths and is ignored. Each site's `.site-state` contains its private Ruflo database, session notes, temporary outputs, and reports and is ignored by that site's Git. Ruflo may also write `.claude`, `.claude-flow`, `.swarm`, and `.ruvector` within the site; these paths are ignored. Back up this state separately when you need its history. Interactive Codex still uses the user's global history; start a new session per site and never use resume/fork across sites.

Shared profiles and skills are installed in the user's Codex directories as directory junctions to this repository. They are optional for building or running any site. The project folder retains its own instructions, brief, assets, code, lockfile, and tests.

The launcher connects the pinned Ruflo MCP for every registered site and exposes only its basic memory store, retrieve, search, list, and stats tools. It excludes unified cross-project search, import, swarm, and neural tools. Other MCPs are chosen per site: for example, Next.js DevTools needs that site's installed package and running dev server, while Playwright needs a site-specific local-origin allowlist. NEUSTAND's optional MCP example remains in its own `config` folder. The blank-site script does not impose a framework or UI library.

Ruflo is pinned at 3.54.1 in this repository. The launch script selects a per-site database with `CLAUDE_FLOW_DB_PATH` and `CLAUDE_FLOW_MEMORY_PATH`, both needed for the installed CLI and MCP memory paths. Other Ruflo subsystems may have their own stores; this script does not claim to isolate all Ruflo features. Do not run cross-site learning, session restore, swarm, or neural commands from this shared repository.

## Next site

From this folder, run `powershell -File scripts/new-site.ps1 -Slug client-slug`, then `powershell -File scripts/open-site.ps1 -Slug client-slug`. The new folder contains only metadata, an empty client brief, Git, and ignored local state. Choose a framework and UI library from that client's brief; no NEUSTAND code or design is copied. The factory has its own Git repository and no remote by default.

## Moving a site and rollback

To move a website to another computer without this workspace, copy or clone the site's own folder, restore its ignored `.env` separately if needed, and run its package manager install and checks. Developer agent links may be absent; they are never needed by the site build. Transfer the ignored site state separately only if its old memory or reports are needed.

Before reversing this migration, preserve any work made since it. The pre-migration backup outside both repositories contains the original shared-tool directories, local settings, site state, and the pre-existing uncommitted files. Copy the original directories and configuration back into the NEUSTAND site, remove only junctions confirmed to target this workspace, and restore the original `.gitignore` and documentation as needed. Do not use `git reset` to discard the pre-existing Hero and animation edits. The factory can then be left unused; neither repository has been staged or committed by this migration.
