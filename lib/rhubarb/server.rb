# Copyright (c) 2011 Daniel T. Swain
# See the file license.txt for copying permissions

require 'gserver'
require 'csv'

module Rhubarb
  class Server < GServer

    SHUTDOWN = "S"
    CLIENTQUIT = "Q"

    @@verbose = false

    @@client_id = 0
    verbose_cmd = {:name => "verbose", :setArgs => 1}
    @@get_commands = [verbose_cmd]
    @@set_commands = [verbose_cmd]

    @@indexed_get_commands = []
    @@indexed_set_commands = []

    @@commands = [
        {:name => "get"},
        {:name => "set"},
        {:name => "ping"}
    ]
    @@index_max = 0

    def self.add_get_command cmd_def
      @@get_commands << cmd_def
    end

    def self.add_set_command cmd_def
      cmd_def[:setArgs] ||= 1
      @@set_commands << cmd_def
    end

    def self.add_get_set_command cmd_def
      add_get_command cmd_def
      add_set_command cmd_def
    end

    def self.add_indexed_set_command cmd_def
      @@indexed_set_commands << cmd_def
    end

    def self.add_indexed_get_command cmd_def
      @@indexed_get_commands << cmd_def
    end

    def self.add_indexed_get_set_command cmd_def
      add_indexed_get_command cmd_def
      add_indexed_set_command cmd_def
    end

    def self.add_command cmd_def
      @@commands << cmd_def
    end

    def client_id
      @@client_id
    end

    def welcomeMessage(args)
      "Welcome to Rhubarb, client #{args[0]}"
    end

    def getVerbose(args, cmd_def)
      @@verbose ? "on" : "off"
    end

    def setVerbose(args, cmd_def)
      if args[2] == "on"
        @@verbose = true
      end
      if args[2] == "off"
        @@verbose = false
      end
      getVerbose(args, cmd_def)
    end

    def respondToPing(words)
      "PONG!"
    end

    private

    def respondToSet(words)
      resp_def = get_command_from_set(words[1], @@indexed_set_commands)

      if resp_def
        respondToIndexedOp(words, "set", resp_def)
      else
        resp_def = get_command_from_set(words[1], @@set_commands)
        responder = get_responder_name_with_prefix(resp_def[:name], "set")
        if resp_def && respond_to?(responder)
          send(responder, words, resp_def)
        else
          unknownCommand({:message => "Unknown Set command"})
        end
      end

    rescue unknownCommand({:message => "Responding to Set command"})

    end

    def respondToGet(words)
      resp_def = get_command_from_set(words[1], @@indexed_get_commands)

      if resp_def
        respondToIndexedOp(words, "get", resp_def)
      else
        resp_def = get_command_from_set(words[1], @@get_commands)
        responder = get_responder_name_with_prefix(resp_def[:name], "get")
        if resp_def && respond_to?(responder)
          send(responder, words, resp_def)
        else
          unknownCommand({:message => "Unknown Get command"})
        end
      end

    rescue unknownCommand({:message => "Responding to Get command"})

    end

    def moded_command? cmd_def
      !cmd_def[:modes].nil?
    end

    def has_command_mode? cmd_def, mode
      return false unless moded_command? cmd_def
      !cmd_def[:modes][mode.to_sym].nil?
    end

    def num_args_needed opwords, cmd_def
      if cmd_def[:modes]
        mode = opwords[0].to_sym
        if has_command_mode?(cmd_def, mode)
          cmd_def[:modes][mode][:setArgs]
        else
          -1
        end
      else
        cmd_def[:setArgs] || -1
      end
    end

    def respondToIndexedSet(opwords, resp_def)

      responder = get_responder_name_with_prefix(resp_def[:name], "set")

      nargs = num_args_needed(opwords, resp_def) #resp_def[:setArgs]

      if moded_command?(resp_def)
        return "Unknown mode #{opwords[0]}" unless has_command_mode?(resp_def, opwords[0])
        mode_setter = responder + "Mode"
        return "Unable to set mode via #{mode_setter}" unless respond_to?(mode_setter)

        mode_set = send(mode_setter, opwords[0])
        return "Unable to set mode to #{opwords[0]}" unless mode_set

        return "#{opwords[0]}" if opwords.size == 1

      end

      needed_mod = nargs + 1# + (moded_command?(resp_def) ? 1 : 0)
      check_size = opwords.size - (moded_command?(resp_def) ? 1 : 0)
      return "Indexing error" unless check_size % (needed_mod) == 0

      response = ""
      response += "#{opwords[0]} " if moded_command?(resp_def)

      start = moded_command?(resp_def) ? 1 : 0

      (start..opwords.size-nargs-1).step(nargs+1) do |w|
        #puts opwords[w]
        if opwords[w].to_i.to_s == opwords[w] && (0..resp_def[:maxIndex]).include?(opwords[w].to_i)
          args = opwords[w+1..w+nargs]
          response += send(responder, opwords[w].to_i, args) + " "
        end
      end
      response = "Indexing error" if response.strip.empty?
      return response

    rescue unknownCommand(:message => "Responding to indexed set")

    end

    def respondToIndexedGet(opwords, resp_def)
      responder = get_responder_name_with_prefix(resp_def[:name], "get")

      do_all = opwords.include?("*")
      response = ""

      if moded_command?(resp_def)
        mode_responder = responder + "Mode"
        unless respond_to?(mode_responder)
          return "Unable to determine mode via #{mode_responder}"
        end
        mode = send(mode_responder)
        unless has_command_mode?(resp_def, mode)
          return "Invalid mode #{mode}"
        end
        response += mode.to_s + " "
      end

      indeces = opwords.reject do
      |o| o.to_i.to_s != o && o.to_i > resp_def[:maxIndex]
      end.map{ |o| o.to_i }
      indeces = (0..resp_def[:maxIndex]) if do_all

      indeces.each do |i|
        response += send(responder, i) + " "
      end
      response = "Indexing error" if response.strip.empty?
      return response

    rescue unknownCommand(:message => "Responding to indexed get")

    end

    def respondToIndexedOp(words, op, resp_def)

      return unknownCommand({:message => "Not Enough Arguments"}) unless words.size >= 3

      opwords = words[2..words.size]
      responder = get_responder_name_with_prefix(resp_def[:name], op)

      if respond_to?(responder)
        if op == "set"
          return respondToIndexedSet(opwords, resp_def)
        elsif op == "get"
          return respondToIndexedGet(opwords, resp_def)
        else
          unkownCommand({:message => "Unknown indexed command"})
        end
      else
        unknownCommand({:message => "No responder"})
      end

      unknownCommand({:message => "No responder present"})

    rescue
      unknownCommand({:message => "Responding to indexed command"})
    end

    def unknownCommand(def_info = {})
      info = {
          :method_name => "",
          :message => "",
          :self_message => ""
      }.merge def_info

      resp = "ERR " + self.class.to_s
      resp += " in method " + info[:method_name] unless info[:method_name].empty?
      resp += ": " + info[:message] unless info[:message].empty?

      in_resp = Time.now.strftime("[%a %b %e %R:%S %Y] ") + self.class.to_s
      in_resp += " " +  self.host.to_s + ":" + self.port.to_s + " ERR "
      in_resp += " in method " + info[:method_name] unless info[:method_name].empty?
      in_resp += ": " + info[:message] unless info[:message].empty?
      in_resp += " + " + info[:self_message] unless info[:self_message].empty?
      puts in_resp

      resp

    end

    def serve(io)
      # Increment the client ID so each client gets a unique ID
      @@client_id += 1
      my_client_id = @@client_id

      io.puts(welcomeMessage([@@client_id]));

      do_shutdown = false

      loop do

        begin
          line = io.readline.strip

          puts "GOT:  |" + line + "|\n" unless !@@verbose

          if line == CLIENTQUIT
            io.puts "Goodbye"
            break
          end

          if line == SHUTDOWN
            io.puts "Goodbye"
            do_shutdown = true
            break
          end

          line = line.downcase

	  # the call to CSV::parse_line is different for Ruby 1.9.x
	  col_sep = ' '
	  if RUBY_VERSION.split('.')[1].to_i > 8
	    col_sep = {:col_sep => col_sep}
	  end
          words = CSV::parse_line(line, col_sep).compact

          cmd_def = get_command_from_set(words[0], @@commands)
          responder = get_responder_name_with_prefix(words[0], "respondTo")

          if respond_to?(responder, true)
            io.puts send(responder, words).strip
          else
            io.puts unknownCommand({:message => "Unknown primary command"})
          end

        rescue
          io.puts "Server error.  Try again."
        end

      end

      if do_shutdown
        self.stop
      end

    end

    def get_command_from_set(command, set)
      set.detect{|c| c[:name].downcase == command.downcase}
    end

    def get_responder_name_with_prefix(command, prefix)
      prefix + command[0].chr.capitalize + command[1..command.size]
    end


  end
end
