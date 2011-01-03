task :default => 'lib/juli/juli_parser.tab.rb'

file 'lib/juli/juli_parser.tab.rb' => 'lib/juli/juli_parser.y' do |t|
  sh "racc #{t.prerequisites[0]}"
end
