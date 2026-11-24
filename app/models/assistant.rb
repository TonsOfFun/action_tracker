# The tracker's side of the agent: which dashboard agent the chat panel talks
# to, and the conversation it keeps per browser session.
#
# The agent itself is not defined in this app's code. It is a record built in
# the dashboard (/activeagents), with the tools from app/agent_tools switched
# on there. The panel appears once such an agent exists.
class Assistant
  SLUG = ENV.fetch("TRACKER_AGENT", "issue-agent")
  ISSUE_TOOLS = %w[find_issues search_issues get_issue].freeze

  Turn = Struct.new(:role, :content, :tools, keyword_init: true)

  class << self
    # The agent named TRACKER_AGENT (default "issue-agent", what the dashboard
    # calls an agent named "Issue Agent"), else the newest agent that was
    # given a tool for reading issues.
    def agent
      runnable = ActionAgent::Agent.where(status: %i[draft active])
      runnable.find_by(slug: SLUG) ||
        runnable.order(updated_at: :desc).detect { |agent| (Array(agent.tools) & ISSUE_TOOLS).any? }
    end

    # The session's conversation with the agent, started on first use. Runs
    # pinned to it are sent its earlier turns, so "assign that one to Sofia"
    # means what it would mean to a person.
    def conversation(agent, session)
      action = ActionAgent::Agent::DEFAULT_ACTION
      ActionAgent::AgentContext.find_by(id: session[:assistant_context_id], contextable: agent, action_name: action) ||
        ActionAgent::AgentContext.create!(
          contextable: agent,
          agent_name: agent.telemetry_agent_class,
          action_name: action,
          instructions: agent.composed_instructions_for(action)
        ).tap { |context| session[:assistant_context_id] = context.id }
    end

    # The conversation as the panel shows it, built from the agent's runs
    # pinned to this session's conversation: what was asked, what came back,
    # and the tools each answer called. Runs record tool calls the same way
    # for every provider, and an evaluation's replays, which are not pinned,
    # stay out of it.
    def turns(agent, session)
      id = session[:assistant_context_id]
      return [] unless id

      chat_runs(agent).select { |run| run.input_params["context_id"].to_i == id.to_i }.flat_map do |run|
        answer = run.output.presence || run.error_message.presence
        [ Turn.new(role: "user", content: run.input_prompt, tools: []),
          (Turn.new(role: "assistant", content: answer, tools: tools_called(run)) if answer) ].compact
      end
    end

    # Runs a person started from the chat panel, oldest first.
    def chat_runs(agent)
      agent.agent_runs.where(status: %i[complete failed]).order(:id)
        .select { |run| run.input_params.to_h["context_id"].present? }
    end

    def tools_called(run)
      Array(run.output_metadata.to_h["tool_calls"]).map { |call| call.is_a?(Hash) ? call["name"] : call }.compact.uniq
    end
  end
end
