# Finish current task
```
some/path/project (branch: feature/JIRA-123) $ ko finish
```
Infers task key from current branch.

# Finish specified task
```
some/path/project (branch: feature/JIRA-987) $ ko AD-123 finish
```
Use specified task key as parameter.

# Start task
```
ko AD-123 start
```

Branch from develop by default, if task is a hotfix branch from master, if
task is a regression bug, branch from release branch (or ask if not possible to
know the release branch)

Task branch name created by: "#{issuetype}/#{key}-#{summary.lowercase.dasherize.remove_duplicated_dashes}"
