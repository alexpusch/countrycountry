class CountiesProvider
  def initialize(folder)
    @folder = folder
  end

  def get_countries_list()
    countries_list = []
    Dir.glob("#{@folder}/*.json") do |filepath|
      country_path = Pathname.new filepath
      country_name = country_path.basename(".geo.json").to_s
      countries_list.push country_name
    end
    countries_list
  end
end