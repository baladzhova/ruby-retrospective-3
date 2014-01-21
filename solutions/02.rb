class Task
	attr_reader :status, :description, :priority, :tags

  def initialize(task)
  	@status, @priority = [task[0], task[2]].map(&:downcase).map(&:to_sym)
  	@description = task[1]
  	@tags = task[3].split(',').map(&:strip)
  end
end

class TodoList
  include Enumerable

  def self.parse(text)
    tasks = text.lines.map do |line|
      Task.new line.split('|').map(&:strip)
    end

    TodoList.new tasks
  end

  def initialize(tasks)
    @todo_list = tasks
  end

  def each(&block)
    @todo_list.each &block
  end

  def filter(criteria)
    TodoList.new @todo_list.select { |task| criteria.fit? task }
  end

  def adjoin(other)
    TodoList.new (@todo_list | other.instance_eval { @todo_list })
  end

  def task_todo
    @todo_list.count { |task| task.status == :todo }
  end

  def tasks_in_progress
    @todo_list.count { |task| task.status == :current }
  end

  def tasks_completed
    @todo_list.count { |task| task.status == :done }
  end

  def completed?
    @todo_list.size == tasks_completed
  end
end

class Criteria
  def initialize(&criteria)
    @criteria = criteria
  end

  class << self
    def status(status)
      new { |task| task.status == status}
    end

    def priority(priority)
      new { |task| task.priority == priority}
    end

    def tags(tags)
      new { |task| tags & task.tags == tags }
    end
  end

  def &(other)
    Criteria.new { |task| fit? task and other.fit? task }
  end

  def |(other)
    Criteria.new { |task| fit? task or other.fit? task }
  end

  def !
    Criteria.new { |task| not fit? task }
  end

  def fit?(task)
    @criteria.call task
  end
end