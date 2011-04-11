# Copyright (c) 2011 Daniel T. Swain
# See the file license.txt for copying permissions

require 'gserver'

class Rhubarb < GServer

  Shutdown_Command = "S";
  ClientQuit_Command = "Q";
  
  def initialize(*args)
    super(*args)

    @@verbose = false

    @@client_id = 0

    @commands = [
                 {:name => "get"},
                 {:name => "set"},
                 {:name => "ping"}
                ]

    verbose_cmd = {:name => "verbose", :setArgs => 1}
    
    @get_commands = [verbose_cmd]
    @set_commands = [verbose_cmd]

    @indexed_get_commands = []
    @indexed_set_commands = []

    @index_max = 0

  end

  def get_command_from_set(command, set)
    set.detect{|c| c[:name].downcase == command}
  end

  def get_responder_name_with_prefix(command, prefix)
    prefix + command[0].chr.capitalize + command[1..command.size]
  end

  def welcomeMessage(args)
    "Welcome to Rhubarb, client #{args[0]}"
  end

  def respondToIndexedOp(words, op, resp_def)

    return unknownCommand({:message => "Not Enough Arguments"}) unless words.size >= 3

    opwords = words[2..words.size]
    responder = get_responder_name_with_prefix(resp_def[:name], op)
    
    if respond_to?(responder)
      if op == "set"
        nargs = resp_def[:setArgs]
        return "Indexing error" unless opwords.size % (nargs + 1) == 0
        response = ""
        (0..opwords.size-nargs-1).step(nargs+1).each{|w|
          if opwords[w].to_i.to_s == opwords[w] && (0..resp_def[:maxIndex]).include?(opwords[w].to_i)
            response += send(responder, opwords[w].to_i, opwords[w+1..w+nargs]) + " "
          end
        }
        response = "Indexing error" if response.strip.empty?
        return response
      elsif op == "get"
        do_all = opwords.include?("*")
        response = ""
        (0..resp_def[:maxIndex]).each{|i|
          response += send(responder, i) + " " if opwords.include?(i.to_s) or do_all
        }
        response = "Indexing error" if response.strip.empty?
        return response
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

  def respondToSet(words)
    resp_def = get_command_from_set(words[1], @indexed_set_commands)    

    if resp_def
      respondToIndexedOp(words, "set", resp_def)
    else
      resp_def = get_command_from_set(words[1], @set_commands)
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
    resp_def = get_command_from_set(words[1], @indexed_get_commands)

    if resp_def
      respondToIndexedOp(words, "get", resp_def)
    else
      resp_def = get_command_from_set(words[1], @get_commands)
      responder = get_responder_name_with_prefix(resp_def[:name], "get")
      if resp_def && respond_to?(responder)
        send(responder, words, resp_def)
      else
        unknownCommand({:message => "Unknown Get command"})
      end
    end

  rescue unknownCommand({:message => "Responding to Get command"})
      
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

        if line == ClientQuit_Command
          io.puts "Goodbye"
          break
        end

        if line == Shutdown_Command
          io.puts "Goodbye"
          do_shutdown = true
          break
        end

        line = line.downcase
        words = line.split(" ")

        cmd_def = get_command_from_set(words[0], @commands)
        responder = get_responder_name_with_prefix(words[0], "respondTo")

        if respond_to?(responder)
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
end
