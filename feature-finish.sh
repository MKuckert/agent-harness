#!/usr/bin/env bash

#- stop Opencode server
#- docker-compose -p "harness-$FEATURE_NAME" down --volumes --remove-orphans
#- Archive plan if not done yet: mv PLAN.md docs/plans/$(date +%Y-%m-%d)_${FEATURE_NAME}.md
#- git commit --allow-empty -S -m "Final review and signature"
#    - alternativ: PLAN.md löschen/verschieben
#- git push
#- cd main
#- git worktree remove
#- cleanup
