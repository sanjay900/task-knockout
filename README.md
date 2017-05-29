# Jira Integration

Jira Command line client using jira REST api. (with some git capabilities while the project is not split: see warning bellow)

## Usage:
```
jira-cli <command> [options] [arguments]
```

- help                 print help information
- branch               create branch for issue
- branches             list existing branches for issue
- filter               print filtered issues
- filters              print current user existing filters
- issue                print information about specified issue
- issue_transitions    list available transitions for specified issue
- myself               print print information about current user
- show_filter          print information about the informed filter
- transition           transition a issue to another state

## Installation:

clone repository
bundle install
edit config/environments.yml
add it to your PATH.

## Warning:
This project will (soon) be split in two:
  - A Jira only command line client
  - A command line integration for jira, git and github workflows.

After such split this repository will become the jira client cappable of drive some of the jira features through command line.

## Notes:

Still in development: something might change.
