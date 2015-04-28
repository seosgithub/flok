#Process one js code file at a time
def macro_process text
  out = StringIO.new

  text.split("\n").each do |l|
    #Send macro
    if l =~ /SEND/
      l.strip!
      l.gsub!(/SEND\(/, "")
      l.gsub! /\)$/, ""
      l.gsub! /\);$/, ""
      o = l.split(",").map{|e| e.strip}

      queue_name = o.shift.gsub(/"/, "")

      res = %{#{queue_name}_q.push.apply(#{queue_name}_q, [#{o.count-1}, #{o.join(", ")}])}
      out.puts res
    else
      out.puts l
    end
  end

  return out.string
end
