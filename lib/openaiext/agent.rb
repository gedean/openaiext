module OpenAIExt
  class Agent
    extend OpenAI
    
    attr_reader :assistant, :thread, :instructions, :vector_store_id

    def initialize(assistant_id: nil, thread_id: nil, thread_instructions: nil, vector_store_id: nil)
      @openai_client = OpenAI::Client.new
      setup_assistant(assistant_id)
      setup_thread(thread_id, vector_store_id)
      @instructions = thread_instructions || @assistant['instructions']
    end

    def add_message(text, role: 'user')
      @openai_client.messages.create(
        thread_id: @thread['id'],
        parameters: { role: role, content: text }
      )
    end

    def messages = @openai_client.messages.list(thread_id: @thread['id'])
    def last_message = messages['data'].first['content'].first['text']['value']
    def runs = @openai_client.runs.list(thread_id: @thread['id'])

    def run(instructions: nil, **options)
      run_id = create_run(instructions, options)
      monitor_run(run_id)
    end

    private

    def setup_assistant(assistant_id)
      assistant_id ||= ENV.fetch('OPENAI_ASSISTANT_ID')
      @assistant = @openai_client.assistants.retrieve(id: assistant_id)
    end

    def setup_thread(thread_id, vector_store_id)
      @vector_store_id = vector_store_id
      thread_params = build_thread_params
      thread_id ||= @openai_client.threads.create(parameters: thread_params)['id']
      @thread = @openai_client.threads.retrieve(id: thread_id)
    end

    def build_thread_params
      return {} unless @vector_store_id
      { tool_resources: { file_search: { vector_store_ids: [@vector_store_id] } } }
    end

    def create_run(instructions, options)
      params = {
        assistant_id: @assistant['id'],
        instructions: instructions || @instructions,
        model: Model.select(options[:model]) || @assistant['model']
      }

      params[:additional_instructions] = options[:additional_instructions] if options[:additional_instructions]
      params[:tool_choice] = options[:tool_choice] if options[:tool_choice]
      
      if options[:additional_message]
        params[:additional_messages] = [{ role: :user, content: options[:additional_message] }]
      end

      @openai_client.runs.create(thread_id: @thread['id'], parameters: params)['id']
    end

    def monitor_run(run_id)
      loop do
        response = @openai_client.runs.retrieve(id: run_id, thread_id: @thread['id'])
        
        case response['status']
        when 'queued', 'in_progress', 'cancelling'
          puts 'Status: Waiting AI Processing finish'
          sleep 1
        when 'completed'
          puts last_message
          break
        when 'requires_action'
          # Handle tool calls (implement as needed)
        when 'cancelled', 'failed', 'expired'
          puts response['last_error'].inspect
          break
        else
          puts "Unknown status response: #{response['status']}"
        end
      end
    end
  end
end
