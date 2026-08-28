# What `settings.json` here does and does not protect

**Read this before citing the deny list as evidence that something is prevented.**

`settings.json` denies `git push`, `git reset --hard` and `git clean`, in both the Bash and
PowerShell forms. Those rules are correct and they are worth keeping. They are also **only
in force when a Claude session's project root is this directory.**

## The failure this file exists to stop repeating

On 2026-08-28 the deny was cited — in a message to another agent, and in the onboarding brief
delivered to the owner — as the control preventing pushes from this repository. It was not.
`git reflog show refs/remotes/origin/main` showed **four pushes, every one after the deny was
written**, three of them that day.

The rule was never overridden. It was never read. Every `claude` process on that machine was
running with `cwd=/Users/user`, one level above this repo, so project settings loaded from
there and this file was not the active config.

## What actually stops a push

```
git config --get remote.origin.pushurl
```

Set to `no_push--see-CLAUDE.md-Article-10`, so the push fails at the git level, from any
session, in any working directory, whatever its permission settings say. `git push
--no-verify` does not bypass it — there is no flag that makes git resolve an unresolvable
URL, which is also why this is stronger than a `pre-push` hook.

Lift it deliberately, never casually: `git config --unset remote.origin.pushurl`

## What is still protected only by this file

`git reset --hard` and `git clean` have **no git-level equivalent**. Article 10's requirement
to preserve someone else's uncommitted work rests on this deny list alone — and therefore
rests on the session being rooted here. Treat that as unenforced when it is not, and do not
delete these entries on the grounds that the push rule turned out to be inert.

## The general rule

A permission file is a statement of intent. It becomes a control only where it is loaded.
Before relying on one, check where the session is actually rooted.
