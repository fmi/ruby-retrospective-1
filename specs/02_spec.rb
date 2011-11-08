describe Collection do
  let(:additional_tags) do
    {
      'John Coltrane' => %w[saxophone],
      'Bach' => %w[piano polyphone],
    }
  end

  let(:input) do
    <<-END
      My Favourite Things.          John Coltrane.      Jazz, Bebop.        popular, cover
      Greensleves.                  John Coltrane.      Jazz, Bebop.        popular, cover
      Alabama.                      John Coltrane.      Jazz, Avantgarde.   melancholic
      Acknowledgement.              John Coltrane.      Jazz, Avantgarde
      Afro Blue.                    John Coltrane.      Jazz.               melancholic
      'Round Midnight.              John Coltrane.      Jazz
      My Funny Valentine.           Miles Davis.        Jazz.               popular
      Tutu.                         Miles Davis.        Jazz, Fusion.       weird, cool
      Miles Runs the Voodoo Down.   Miles Davis.        Jazz, Fusion.       weird
      Boplicity.                    Miles Davis.        Jazz, Bebop
      Autumn Leaves.                Bill Evans.         Jazz.               popular
      Waltz for Debbie.             Bill Evans.         Jazz
      'Round Midnight.              Thelonious Monk.    Jazz, Bebop
      Ruby, My Dear.                Thelonious Monk.    Jazz.               saxophone
      Fur Elise.                    Beethoven.          Classical.          popular
      Moonlight Sonata.             Beethoven.          Classical.          popular
      Pathetique.                   Beethoven.          Classical
      Toccata e Fuga.               Bach.               Classical, Baroque. popular
      Goldberg Variations.          Bach.               Classical, Baroque
      Eine Kleine Nachtmusik.       Mozart.             Classical.          popular, violin
    END
  end

  let(:collection) { Collection.new input, additional_tags }

  it "returns all entries if called without parameters" do
    collection.find({}).should have(input.lines.count).items
  end

  it "can look up songs by artist" do
    songs(artist: 'Bill Evans').map(&:name).should =~ ['Autumn Leaves', 'Waltz for Debbie']
  end

  it "can look up songs by name" do
    songs(name: "'Round Midnight").map(&:artist).should =~ ['John Coltrane', 'Thelonious Monk']
  end

  it "uses the genre and subgenre as tags" do
    song(name: 'Miles Runs the Voodoo Down').tags.should include('jazz', 'fusion')
  end

  it "can find songs by tag" do
    songs(tags: 'baroque').map(&:name).should =~ ['Toccata e Fuga', 'Goldberg Variations']
  end

  it "can find songs by multiple tags" do
    songs(tags: %w[popular violin]).map(&:name).should eq ['Eine Kleine Nachtmusik']
  end

  it "can find songs that don't have a tag" do
    songs(tags: %w[weird cool!]).map(&:name).should eq ['Miles Runs the Voodoo Down']
  end

  it "can filter songs by a lambda" do
    songs(filter: ->(song) { song.name == 'Autumn Leaves' }).map(&:name).should eq ['Autumn Leaves']
  end

  it "adds the artist tags to the songs" do
    songs(tags: 'polyphone').map(&:name).should =~ ['Toccata e Fuga', 'Goldberg Variations']
  end

  it "allows multiple criteria" do
    songs(name: "'Round Midnight", tags: 'bebop').map(&:artist).should eq ['Thelonious Monk']
  end

  it "allows all criteria" do
    songs(
      name: "'Round Midnight",
      tags: 'bebop',
      artist: 'Thelonious Monk',
      filter: ->(song) { song.genre == 'Jazz' },
    ).map(&:artist).should eq ['Thelonious Monk']
  end

  it "constructs an object for each song" do
    song = collection.find(name: 'Tutu').first

    song.name.should      eq 'Tutu'
    song.artist.should    eq 'Miles Davis'
    song.genre.should     eq 'Jazz'
    song.subgenre.should  eq 'Fusion'
    song.tags.should      include('weird', 'cool')
  end

  def songs(options = {})
    collection.find(options)
  end

  def song(options = {})
    songs(options).first
  end
end
