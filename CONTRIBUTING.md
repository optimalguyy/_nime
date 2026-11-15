# Contributing to `_nime`

Thanks for taking the time to help. `_nime` is one shell script, so the bar to
start is low: open `_nime`, change it, run it.

## Before you open a pull request

- Run `sh -n _nime` (or `bash -n _nime`). It has to parse.
- Run `shellcheck _nime` if you have it. Fix what is real; leave the deliberate
  `SC2086`-style word splitting where flags are meant to expand.
- Run `_nime --check-deps` and `_nime -h`, and try a real search on both
  sources with `-s`.
- Keep the script POSIX `sh`. No bashisms, no arrays, no `local`. It is the
  same script on Debian dash, Alpine busybox ash and Termux.
- Bump `version=` when behaviour changes, and add the option to `_nime.1` and
  to the README table at the same time.

## Adding a source

Three functions are enough; the rest of the script does not care.

1. `xx_search <encoded query>` prints `value<TAB>label` lines.
2. `xx_episode_maps <id>` prints the same shape: one line per episode.
3. Either an embed resolver used by `provider_embed`, or a direct url if the
   site publishes one.

Then add the name to the `provider_search`, `provider_episode_maps` and
`provider_embed` dispatch, to the help text, the man page and the README.

## Fixing a broken scrape

The sites change markup without warning, and the parser is regex based on
purpose so it stays readable. When something breaks:

```sh
# see what the endpoint actually returns
curl -sSL -A "$AGENT" 'https://animesuge.cz/ajax/anime/search?keyword=<title>' \
  -H 'X-Requested-With: XMLHttpRequest' | head -c 2000
```

Compare that against the `sed`/`grep` expressions in the matching `as_*` or
`ac_*` function and adjust the smallest possible pattern.

## Style

- Tabs for indentation.
- Functions are `snake_case`, internal temporaries are `_underscored` so they
  do not leak into the global scope.
- User facing output goes through `info`, `warn` or `die`. Nothing prints bare
  `echo`.
- No new dependency unless the feature genuinely cannot be done with `sh` and
  the four required tools.
- The tool never installs anything, never runs a package manager and never
  needs root. Keep it that way.

## Reporting a bug

Include the source you used, the episode, the output of `_nime --version` and
`_nime --check-deps`, and the smallest failing command. If playback broke,
say which player. Do not paste stream urls with tokens in them.
