#!/usr/bin/env ruby

def prepend(number)
  return number <= 9 ? ("0" + number.to_s) : number.to_s
end

for year in ['12', '13'] do
  for month in ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'] do
    for day in (1..31) do
      day = prepend(day)
      unless File.exist?("data/20#{year}-#{month}-#{day}-23.json.gz")
        system "wget -P data/ http://data.githubarchive.org/20#{year}-#{month}-#{day}-{0..24}.json.gz"
      else
        puts "Skipped file...\n\n\n"
      end
    end
  end
end

