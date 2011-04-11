rhubarb
==================

rhubarb is Copyright (c) 2011 by Daniel Swain, dan.t.swain at gmail.com.

What is rhubarb?
------------------

rhubarb is a lightweight and extensible inter-process communication
(IPC) server.  rhubarb is a base class, written in ruby, with the
intention that you add your own functionality by subclassing it.

Communication with rhubarb is via lines of text and therefore clients
can be written in any language with socket support.  The
sample_server.rb file should give you an idea of what's possible.

How do I use it?
------------------

Here's a simple example.  Suppose that you want the value of a
variable, let's call it "ultimateAnswer", to be available for several
different programs to get and set.

The first step is to subclass rhubarb, add a class variable to store
the value of "ultimateAnswer", and add a command definition to the
@get_commands and @set_commands arrays:

    class LUEServer < Rhubarb
     
      def initialize(*args)
        super(*args)
     
        @ultimateAnswer = 42
        
        command_def = {:name => "ultimateAnswer", :setArgs => 1}
     
        @get_commands << command_def
        @set_commands << command_def
     
    end

    
