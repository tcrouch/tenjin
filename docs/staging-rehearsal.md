# Staging rehearsal

`bin/staging` builds a throwaway copy of production on the target Heroku
stack so a deploy can be rehearsed end to end before it touches
`ogat-tenjin`. It costs about $0.60 a day (two Basic dynos and an
Essential-0 database) plus pennies for the scratch bucket, and is destroyed
afterwards.

## Why

Production runs the June 2024 build on heroku-20: Ruby 2.7, Rails 6.1 and
the React frontend. master is Ruby 3.4, Rails 7.2 and Hotwire. The stack is
end of life and blocks builds, so the next deploy also moves to heroku-24.
Nothing between those two points has run in front of users, and the first
weeks of term are the wrong time to find out what breaks.

## Run

```
bin/staging create
bin/staging copy-db
bin/staging copy-s3
bin/staging deploy            # master; or a branch: bin/staging deploy fix/schema-foreign-keys
bin/staging smoke
bin/staging logins            # prints a student, teacher, school admin and platform admin login
bin/staging destroy           # when finished
```

Requirements: the Heroku CLI logged in as a member of the outwood team, and
the AWS CLI with a profile that can read the production bucket, create a
bucket, set its policy and CORS, and look up the app's IAM user.
`DRY_RUN=1` prints every mutating command instead of running it, and every
step can be re-run.

## What staging deliberately lacks

- HireFire: the worker is scaled by hand to one dyno.
- Scout and Rollbar: no monitoring tokens, so nothing reports as production.
- Wonde and Google sign-in: their callbacks are registered for
  tenjin.outwood.com only. Use username and password logins on staging;
  single sign-on is verified on production straight after the real deploy.
- Scheduler add-ons: run the rake tasks with `heroku run` instead.
- `NODE_OPTIONS=--openssl-legacy-provider`: a webpack 4 workaround. Staging
  proves the new build does not need it, and deploy day drops it.
- Public read on the bucket: production's bucket carries a legacy AllUsers
  READ grant. The scratch bucket does not and does not need it, because the
  app serves signed URLs.
- Mail: production has no SMTP configured, so there is nothing to neuter.

## Checklist

- [ ] Build: pnpm install and the Shakapacker compile succeed without NODE_OPTIONS
- [ ] Release phase: migrations run (`heroku releases:output -a ogat-tenjin-staging`)
- [ ] Memory: `heroku logs -a ogat-tenjin-staging --dyno web | grep memory_total` stays well under 512 MB across a few minutes of use
- [ ] Student (from `bin/staging logins`): dashboard, start a quiz by subject, by topic and by lucky dip, answer through to the end, points and streak update, the live leaderboard updates in a second tab
- [ ] Teacher: the classroom page renders the student table and search works, set a homework, homework progress shows, flag a question
- [ ] Author: edit a question with Trix, edit a lesson and a topic, upload an image (it lands in the scratch bucket) and see it render
- [ ] School admin: user list, the reset-passwords job enqueues and the worker runs it, the sync button fails cleanly without Wonde credentials
- [ ] Platform admin: `/admins/sign_in`, then the system area for schools, school groups and subjects
- [ ] Worker: `heroku ps` shows it up and `Delayed::Job.count` drains after the jobs above
- [ ] Scheduled tasks: `heroku run rake challenges:add_challenges daily_updates:update_counts maintenance:regular_jobs -a ogat-tenjin-staging` completes without error
- [ ] Browser console: no failed asset loads, and ActionCable connects
- [ ] `heroku logs -a ogat-tenjin-staging -n 2000` shows no exceptions

## Deploy day

Rehearsed already, so the production deploy is these steps, run outside
school hours. Rails 7 changes the cookie key generator, so every session and
remember-me cookie is invalidated at the moment of release. Avoid the
database maintenance window, Fridays 22:30 to Saturdays 02:30 UTC.

1. `heroku pg:backups:capture -a ogat-tenjin`
2. `heroku stack:set heroku-24 -a ogat-tenjin`
3. `heroku config:unset NODE_OPTIONS -a ogat-tenjin`, if staging built without it
4. Rotate the secret, keeping the old one for the re-sign step. Every release,
   including a config change, runs the release phase, so this is harmless on
   the old slug:
   `heroku config:set OLD_SECRET_KEY_BASE="$(heroku config:get SECRET_KEY_BASE -a ogat-tenjin)" SECRET_KEY_BASE="$(openssl rand -hex 64)" -a ogat-tenjin >/dev/null`
   A config change is not visible until the release phase it triggers has
   finished, so wait for `heroku releases -a ogat-tenjin` to show that release
   succeeded, then confirm the value took:
   `heroku config:get OLD_SECRET_KEY_BASE -a ogat-tenjin | wc -c` must print 129.
   Running the re-sign step before that point sees the previous environment
   and fails with every id unverifiable.
5. `git push https://git.heroku.com/ogat-tenjin.git master:master`
6. Watch `heroku releases:output -a ogat-tenjin` and `heroku logs --tail -a ogat-tenjin`
7. Re-sign the Action Text attachments, which stop resolving under the Rails 7
   key derivation: `heroku run rake rich_text:resign_attachment_sgids -a ogat-tenjin`.
   Expect `re-signed 666` or thereabouts and `unverifiable 0`; a non-zero
   unverifiable count means the old secret is wrong, and the task refuses to
   guess. Embedded images show as ☒ until this runs.
8. `heroku config:unset OLD_SECRET_KEY_BASE -a ogat-tenjin`, keeping the old value in the
   team password store until the rollback window has passed
9. Verify on production: an embedded question image renders, Wonde sign-in, Google sign-in, HireFire scales a worker when a job is queued, Scout receives data, and the scheduler jobs still name existing rake tasks
10. If anything is wrong, roll back in this order. The schema migration in this
    deploy relaxes a NOT NULL on Active Storage blobs, which the old code
    tolerates, but re-signed attachments do not verify under the old code, so
    they are signed back first, while the new slug can still run the task:
    1. `heroku config:set OLD_SECRET_KEY_BASE=<pre-rotation secret> -a ogat-tenjin >/dev/null`, wait for that release, confirm the length as in step 4
    2. `heroku run rake rich_text:downgrade_attachment_sgids -a ogat-tenjin`, expect `re-signed 666` or thereabouts and `unverifiable 0`
    3. `heroku rollback -a ogat-tenjin`, which restores the previous slug and its heroku-20 stack
    4. `heroku config:set SECRET_KEY_BASE=<pre-rotation secret> -a ogat-tenjin >/dev/null`, then `heroku config:unset OLD_SECRET_KEY_BASE -a ogat-tenjin`

    If the new slug cannot run a one-off dyno, restore the step 1 backup with
    `heroku pg:backups:restore` instead of the first two steps.

A few days after a clean deploy, the schema-hardening series follows in two
releases, `fix/schema-foreign-keys` then `fix/schema-not-null`, with
`db/integrity_checks.sql` run against production between them. Rehearse each
with `bin/staging deploy <branch>` first.
