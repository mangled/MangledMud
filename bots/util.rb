# some common utilities for bots

module Utilities

  def Utilities.look(session)
    location = OpenStruct.new
    location.exits = []
    location.players = []
    m = /(.*)Contents:(.*)Exits:(.*)/m.match(session.cmd('examine here'))
    if m
      if m[1] =~ /^(.*?)\(#(\d+)\)/
        location.name = $1
        location.id = $2
      end
      Utilities.extract_item(session, m[2], /Type:\s+Player/) {|player_name, player_id| location.players << OpenStruct.new(:name => player_name, :id => player_id) }
      Utilities.extract_item(session, m[3], /Destination:\s+(.*?)\(\#(\d+)\)/) do |names, id, dest, destid|
        location.exits << OpenStruct.new(
          :names => names,
          :name => names.partition(';')[0],
          :id => id,
          :destname => dest,
          :destid => destid
        )
      end
    end
    location
  end
  
  def Utilities.extract_item(session, s, type)
    m = s.scan(/\s*(.+)\(#(\d+)\)\s*/)
    m.each do |item|
      info = session.cmd("examine ##{item[1]}")
      m = type.match(info)
      yield item + m[1..-1] if m
    end
  end
end