require "test_helper"

class ConversationScenariosTest < ActiveSupport::TestCase
  setup do
    @agent = ActionAgent::Agent.create!(name: "Issue Agent", provider: "anthropic", model: "claude-haiku-4-5",
                                        instructions: "Help with the backlog.", tools: IssueTools.tool_names)
    @context = ActionAgent::AgentContext.create!(contextable: @agent, agent_name: "IssueAgent", action_name: "ask")
  end

  test "each chat message becomes a scenario expecting the tools its answer called" do
    chat "What is urgent?", tools: %w[find_issues get_user]
    chat "Thanks!"

    urgent, thanks = ConversationScenarios.new(@agent).call

    assert_equal [ "What is urgent?", { "tools" => %w[find_issues get_user] } ], urgent.values_at("prompt", "expectations")
    assert_equal [ "Thanks!", {} ], thanks.values_at("prompt", "expectations")
  end

  test "an evaluation's own replays are not conversations" do
    chat "What is urgent?", tools: %w[find_issues]
    @agent.agent_runs.create!(input_prompt: "A replayed scenario", status: :complete, trace_id: SecureRandom.uuid,
                              input_params: { "model_override" => "some-model" }, output: "Done.")

    assert_equal [ "What is urgent?" ], ConversationScenarios.new(@agent).call.pluck("prompt")
  end

  test "the same question asked twice is one scenario, so merging again adds nothing" do
    2.times { chat "What is urgent?", tools: %w[find_issues] }
    evaluation = ActionAgent::Evaluation.create!(agent: @agent, name: "Real conversations", judge_kind: "llm", sample_size: 20,
                                                 criteria: [ { "key" => "response_present", "type" => "response_present" } ])

    assert_equal 1, evaluation.merge_scenarios!(ConversationScenarios.new(@agent).call)[:added].size
    assert_equal 1, evaluation.merge_scenarios!(ConversationScenarios.new(@agent).call)[:unchanged].size
  end

  test "the chat panel shows a conversation's turns with the tools behind each answer" do
    chat "What is urgent?", tools: %w[find_issues]

    user, assistant = Assistant.turns(@agent, { assistant_context_id: @context.id })

    assert_equal [ "user", "What is urgent?" ], [ user.role, user.content ]
    assert_equal [ "assistant", "An answer.", %w[find_issues] ], [ assistant.role, assistant.content, assistant.tools ]
  end

  private

  def chat(message, tools: [])
    @agent.agent_runs.create!(input_prompt: message, status: :complete, trace_id: SecureRandom.uuid, output: "An answer.",
                              input_params: { "context_id" => @context.id },
                              output_metadata: { "tool_calls" => tools, "context_id" => @context.id })
  end
end
