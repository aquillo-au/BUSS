namespace :db do
  task import_from_sqlite: :environment do
    require 'json'

    [
      { file: 'people.json', model: Person },
      { file: 'incidents.json', model: Incident },
      { file: 'notes.json', model: Note },
      { file: 'sign_ins.json', model: SignIn }
    ].each do |item|
      next unless File.exist?(item[:file])

      records = JSON.parse(File.read(item[:file]))
      records.each { |record| item[:model].create!(record) }
      puts "Imported #{records.count} #{item[:model]} records"
    end

    puts "All data imported successfully!"
  end
end
