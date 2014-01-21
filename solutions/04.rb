module Asm
  module InstructionsQueue
    Instruction = Struct.new :name, :operands

    INSTRUCTIONS = {
      je:  :==,
      jne: :!=,
      jl:  :<,
      jle: :<=,
      jg:  :>,
      jge: :>=,
      jmp: nil,
      mov: nil,
      inc: nil,
      dec: nil,
      cmp: nil,
    }.freeze

    INSTRUCTIONS.keys.each do |name|
      define_method name do |*args|
        @instructions_queue << Instruction.new(name, [*args])
      end
    end
  end

  class Evaluator
    include InstructionsQueue
    REGISTERS = [:ax, :bx, :cx, :dx].freeze

    def initialize
      @registers = REGISTERS.reduce({}) { |hash, name| hash.merge(name => 0) }
      @instructions_queue = []
      @labels = {}
      @last_cmp_result = 0
      @instruction_pointer = 0
    end

    def label(name)
      @labels[name] = @instructions_queue.size
    end

    def execute
      while @instruction_pointer < @instructions_queue.size
        name = @instructions_queue[@instruction_pointer].name
        operands = @instructions_queue[@instruction_pointer].operands

        if name.to_s.start_with? 'j'
          call_jump name, operands[0]
        else
          call_instruction name, operands[0], operands[1]
          @instruction_pointer += 1
        end
      end
    end

    def call_instruction(name, register, value)
      case name
        when :mov
          @registers[register] = extract(value)
        when :inc
          @registers[register] += extract(value)
        when :dec
          @registers[register] -= extract(value)
        when :cmp
          @last_cmp_result = extract(register) <=> extract(value)
      end
    end

    def call_jump(jump, where)
      if jump != :jmp and not @last_cmp_result.public_send INSTRUCTIONS[jump], 0
        @instruction_pointer += 1
      else
        @instruction_pointer = @labels[where]
      end
    end

    def method_missing(name)
      name.to_sym
    end

    def extract(value)
      @registers[value] or value or 1
    end

    def output
      @registers.values
    end
  end

  def self.asm(&block)
    evaluator = Evaluator.new
    evaluator.instance_eval &block
    evaluator.execute
    evaluator.output
  end
end