require 'optparse'
require 'mime/types'
require 'phash/text'
require 'phash/audio'
require 'phash/image'
require 'phash/video'

folder     = ARGV[0]
thresholds = { text: 0.5, audio: 0.6, image: 0.6, video: 0.5, binary: 1.0 }

text_group   = { name: :text,   files: [], type: 'T' }
audio_group  = { name: :audio,  files: [], type: 'A' }
image_group  = { name: :image,  files: [], type: 'I' }
video_group  = { name: :video,  files: [], type: 'V' }
binary_group = { name: :binary, files: [] }

file_groups = [text_group, audio_group, image_group, video_group, binary_group]

OptionParser.new do |opts|
  opts.on('-t', '--text STHRESHOLD',  Float)
  opts.on('-a', '--audio STHRESHOLD', Float)
  opts.on('-i', '--image STHRESHOLD', Float)
  opts.on('-v', '--video STHRESHOLD', Float)
end.parse!(into: thresholds)

Dir.glob("#{folder}/*")
   .select { |f| File.file? f }
   .map(&File.method(:realpath)).each do |file|
  case MIME::Types.type_for(file).first.media_type
  when 'text'
    text_group[:files] << Phash::Text.new(file)
  when 'audio'
    audio_group[:files] << Phash::Audio.new(file)
  when 'image'
    image_group[:files] << Phash::Image.new(file)
  when 'video'
    video_group[:files] << Phash::Video.new(file)
  end
  if MIME::Types.type_for(file).first.binary?
    binary_group[:files] << Phash::Text.new(file)
  end
end

file_groups.each do |group|
  if group[:files].length() >= 2
    group[:files].combination(2) do |a, b|
      similarity = a % b
      if similarity >= thresholds[group[:name]]
        puts "#{a.path}\t#{b.path}\t#{similarity}\t" \
             "#{group[:name] == :binary ? '' : group[:type]}"
      end
    end
  end
end
