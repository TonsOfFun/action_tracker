# Builds evaluation scenarios from the conversations people have had with an
# agent: every message sent from the chat panel becomes a scenario, keyed by
# its text so running this again adds only what is new.
#
# Where the agent answered a message by calling tools, those tools become the
# scenario's expectation: a later version of the agent that stops reaching for
# them fails the scenario. A message it answered without tools carries no
# expectation, and is left to the judge.
class ConversationScenarios
  def initialize(agent)
    @agent = agent
  end

  # @return [Array<Hash>] scenario attributes for Evaluation#merge_scenarios!
  def call
    turns.uniq { |turn| turn[:prompt].downcase }.map do |turn|
      {
        "key" => "chat-#{Digest::SHA1.hexdigest(turn[:prompt].downcase)[0, 10]}",
        "group" => "From conversations",
        "prompt" => turn[:prompt],
        "expectations" => turn[:tools].any? ? { "tools" => turn[:tools] } : {}
      }
    end
  end

  private

  def turns
    Assistant.chat_runs(@agent).filter_map do |run|
      next unless run.complete? && run.input_prompt.present?

      { prompt: run.input_prompt.strip, tools: Assistant.tools_called(run) }
    end
  end
end
