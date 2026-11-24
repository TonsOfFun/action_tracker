# frozen_string_literal: true

ActionAgent.configure do |config|
  # A demo on a laptop: no sign-in. With this unset the dashboard is open in
  # development and test, and answers 403 everywhere else.
  config.authentication_method = nil

  # The tools the agent editor offers, named explicitly because two of the
  # classes concern issues: IssueTools reads, IssueActionTools writes.
  config.schema_tools = %w[IssueTools UserTools IssueActionTools]

  # Checkout sandboxes on this machine: the dashboard clones a repository,
  # boots it beside itself and can run a coding session in the copy. This is
  # what lets it try a change to the tools and open a pull request for it.
  # The local backend runs the checkout's code as your own user, so it is for
  # a developer's machine; it is off outside development and test.
  config.sandbox_service = :local

  # Coding sessions use this machine's own Claude Code login (`claude /login`),
  # so no key for them is stored in the dashboard.
  config.claude_code_auth = :local_login

  # Connecting GitHub (Settings -> Integrations) needs an OAuth app; its id
  # and secret are read from GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET. Public
  # repositories are all the demo needs.
  config.github_oauth_scopes = "public_repo read:user"
end
