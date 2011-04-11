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

    @get_commands = []
    @set_commands = []

    @get_commands_indexed = []
    @set_commands_indexed = []

    @index_max = 0

  end

  def welcomeMessage(args)
    "Welcome to Rhubarb, client #{args[0]}"
  end

  def respondToIndexedOp(words, op, resp_def)

    return unknownCommand({:message => "Not Enough Arguments"}) unless words.size >= 3

    opwords = words[2..words.size]
    responder = op + resp_def[:name].capitalize
    
    if respond_to?(responder)
      if op == "set"
        nargs = resp_def[:setArgs]
        return "Indexing error" unless opwords.size % (nargs + 1) == 0
        response = ""
        (0..opwords.size-nargs-1).step(nargs+1).each{|w|
          if opwords[w].to_i.to_s == opwords[w] && (0..resp_def[:max_index]).include?(opwords[w].to_i)
            response += send(responder, opwords[w].to_i, opwords[w+1..w+nargs])
          end
        }
        response = "Indexing error" if response.strip.empty?
        return response
      elsif op == "get"
        do_all = opwords.include?("*")
        response = ""
        (0..resp_def[:max_index]).each{|i|
          response += send(responder, i) if opwords.include?(i.to_s) or do_all
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
    resp_def = @indexed_set_commands.detect{|c| c[:name] == words[1]}

    if resp_def
      respondToIndexedOp(words, "set", resp_def)
    else
      resp_def = @set_commands.detect{|c| c[:name] == words[1]}
      if resp_def && respond_to?("set" + words[1].capitalize)
        send("set" + words[1].capitalize, words, resp_def)
      else
        unknownCommand({:message => "Unknown Set command"})
      end
    end

  rescue unknownCommand({:message => "Responding to Set command"})
      
  end

  
  def respondToGet(words)
    resp_def = @indexed_get_commands.detect{|c| c[:name] == words[1]}

    if resp_def
      respondToIndexedOp(words, "get", resp_def)
    else
      resp_def = @get_commands.detect{|c| c[:name] == words[1]}
      if resp_def && respond_to?("get" + words[1].capitalize)
        send("get" + words[1].capitalize, words, resp_def)
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

        cmd_def = @commands.detect{|c| c[:name] == words[0]}
        responder = "respondTo" + words[0].capitalize

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
