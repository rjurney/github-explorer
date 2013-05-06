#!/usr/bin/env ruby

for year in ['12', '13'] do
  for month in ['00', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11'] do
      system "wget -P data/ http://data.githubarchive.org/20#{year}-#{month}-{01..31}-{0..23}.json.gz"
  end
end
