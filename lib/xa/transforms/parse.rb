require 'parslet'

module XA
  module Transforms
    module Parse
      class Parser < Parslet::Parser
        rule(:adaptss) { str('ADAPTS') }
        rule(:makes)   { str('MAKE') }
        rule(:uses)    { str('USE') }
        rule(:ass)     { str('AS') }

        rule(:space)   { match('\s').repeat(1) }
        rule(:name)    { match('\w+').repeat(1) }
        rule(:path)    { match('[\w\.]+').repeat(1) }

        rule(:use)     { uses.as(:action) >> space >> path.as(:path) >> space >> ass >> space >> name.as(:column) }
        rule(:make)    { makes.as(:action) >> space >> name.as(:table) }
        rule(:adapts)  { adaptss.as(:action) >> space >> name.as(:method) }
        
        rule(:line)    { adapts | make | use }
        
        root(:line)
      end
      
      def parse(lines)
        @table = nil
        lines.inject({}) do |o, ln|
          res = parser.parse(ln)
          interpret(o, res)
        end
      end

      private

      def interpret(o, res)
        send("interpret_#{res.fetch(:action).str.downcase}", o, res) 
      end

      def interpret_adapts(o, res)
        o.merge('adapts' => res[:method].str)
      end

      def interpret_make(o, res)
        @table = res[:table].str
        o.merge('tables' => o.fetch('tables', {}).merge(@table => {}))
      end

      def interpret_use(o, res)
        o['tables'][@table][res[:column].str] = res[:path].str if @table
        o
      end
      
      def interpret_nothing(o, res)
      end
      
      def parser
        @parser ||= Parser.new
      end
    end
  end
end
