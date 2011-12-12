# Attempt to configure the "env" file with the correct ruby paths
# for the Makefile
# Running this updates the "env" file, included by Makefile
# *** This is likely to not work! ***
require 'rbconfig'

env = open("env", "w")
env.write("# Auto-generated, see make.rb\n")
env.write("RUBY = #{RbConfig::CONFIG["rubyhdrdir"]}\n")
env.write("ARCH = #{File.join(RbConfig::CONFIG["rubyhdrdir"],RbConfig::CONFIG["arch"])}\n")

