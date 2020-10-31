# frozen_string_literal: true

require 'benchmark'


UNACCENT = {
  'Ä'=>'A',  'ä'=>'a',
  'Á'=>'A',  'á'=>'a',
  'Æ'=>'AE', 'æ'=>'ae',
  'É'=>'E',  'é'=>'e',
  'Í'=>'I',  'í'=>'i',
             'ï'=>'i',
  'Ñ'=>'N',  'ñ'=>'n',
  'Ö'=>'O',  'ö'=>'o',
  'Ó'=>'O',  'ó'=>'o',
  'Œ'=>'OE', 'œ'=>'oe', 
             'ß'=>'ss',
  'Ü'=>'U',  'ü'=>'u',
  'Ú'=>'U',  'ú'=>'u',
}


def unaccent_each_char( text, mapping=UNACCENT )
  buf = String.new
  text.each_char do |ch|
    buf << if mapping[ch]
                mapping[ch]
            else
                ch
            end
  end
  buf
end

def unaccent_each_char_v2( text, mapping=UNACCENT )
  buf = String.new
  text.each_char do |ch|
    buf << (mapping[ch] || ch)
  end
  buf
end

def unaccent_each_char_v2_7bit( text, mapping=UNACCENT )
  buf = String.new
  text.each_char do |ch|
    buf <<   if ch.ord < 0x7F   # no mapping (ever) for 7-bit unicode latin basic (a.k.a. ascii) chars
               ch
             else
               mapping[ch] || ch
             end
  end
  buf
end

UNACCENT_FASTER = UNACCENT.reduce( [] ) do |ary,(ch,value)|   # use/try array lookup by char (ord) integer number
  ary[ ch.ord ] = value
  ary
end

def unaccent_each_char_v2_7bit_faster( text, mapping_faster=UNACCENT_FASTER )
  buf = String.new
  text.each_char do |ch|
    buf <<  if ch.ord < 0x7F   # no mapping (ever) for 7-bit unicode latin basic (a.k.a. ascii) chars
               ch
            else
               mapping_faster[ ch.ord ] || ch
            end
  end
  buf
end



def unaccent_each_char_reduce( text, mapping=UNACCENT )
  text.each_char.reduce( String.new ) do |buf,ch|
    buf <<  if mapping[ch]
                mapping[ch]
            else
                ch
            end
    buf
  end
end

def unaccent_each_char_reduce_v2( text, mapping=UNACCENT )
  text.each_char.reduce( String.new ) do |buf,ch|
    buf << (mapping[ch] || ch)
    buf
  end
end

def unaccent_chars_reduce( text, mapping=UNACCENT )
  text.chars.reduce( String.new ) do |buf,ch|
    buf << (mapping[ch] || ch)
    buf
  end
end


def unaccent_chars_map_join( text, mapping=UNACCENT )
  text.chars.map { |ch| mapping[ch] || ch }.join
end



ANY_CHAR_REGEX = /./     # use/try constant regex for speed-up
def unaccent_scan( text, mapping=UNACCENT )
  buf = String.new
  text.scan( ANY_CHAR_REGEX ) do |ch|
    buf << if mapping[ch]
                mapping[ch]
            else
                ch
            end
  end
  buf
end

NON_ALPHA_CHAR_REGEX = /[^A-Za-z0-9 ]/    # use/try constant regex for speed-up
def unaccent_gsub( text, mapping=UNACCENT )
  ## todo/fix: use all ascii (basic latin) chars below 0x7F - why? why not?
  text.gsub( NON_ALPHA_CHAR_REGEX ) do |ch|
    if mapping[ch]
      mapping[ch]
    else
      ch
    end
  end
end

def unaccent_gsub_v2( text, mapping=UNACCENT )
  text.gsub( NON_ALPHA_CHAR_REGEX ) do |ch|
    mapping[ch] || ch
  end
end

def unaccent_gsub_v3a( text, mapping=UNACCENT )
  text.gsub( NON_ALPHA_CHAR_REGEX, mapping )
end

UNACCENT_REGEX = Regexp.union( UNACCENT.keys )
def unaccent_gsub_v3b( text, mapping=UNACCENT, regex=UNACCENT_REGEX )
  text.gsub( regex, mapping)
end




def benchmark( str, mapping=UNACCENT,
                    mapping_faster=UNACCENT_FASTER,
                    regex=UNACCENT_REGEX,   n: 20_000 )
  puts "text=>#{str}<, n=#{n}:"
  Benchmark.bm(24) do |benchmark|
    benchmark.report( 'each_char' ) do
      n.times { unaccent_each_char( str, mapping ) }
    end

    benchmark.report( 'each_char_v2' ) do
      n.times { unaccent_each_char_v2( str, mapping ) }
    end

    benchmark.report( 'each_char_v2_7bit' ) do
      n.times { unaccent_each_char_v2_7bit( str, mapping ) }
    end

    benchmark.report( 'each_char_v2_7bit_faster' ) do
      n.times { unaccent_each_char_v2_7bit_faster( str, mapping_faster ) }
    end

    benchmark.report( 'each_char_reduce' ) do
      n.times { unaccent_each_char_reduce( str, mapping ) }
    end

    benchmark.report( 'each_char_reduce_v2' ) do
      n.times { unaccent_each_char_reduce_v2( str, mapping ) }
    end

    benchmark.report( 'chars_reduce' ) do
      n.times { unaccent_chars_reduce( str, mapping ) }
    end

    benchmark.report( 'chars_map_join' ) do
      n.times { unaccent_chars_map_join( str, mapping ) }
    end

    benchmark.report( 'gsub' ) do
      n.times { unaccent_gsub( str, mapping ) }
    end

    benchmark.report( 'gsub_v2' ) do
      n.times { unaccent_gsub_v2( str, mapping ) }
    end

    benchmark.report( 'gsub_v3a' ) do
      n.times { unaccent_gsub_v3a( str, mapping ) }
    end

    benchmark.report( 'gsub_v3b' ) do
      n.times { unaccent_gsub_v3b( str, mapping, regex ) }
    end

    benchmark.report( 'scan' ) do
      n.times { unaccent_scan( str, mapping ) }
    end
  end
end



factor = 5
str1 = 'AÄÁaäá EÉeé IÍiíï NÑnñ OÖÓoöó Ssß UÜÚuüú' * factor
str2 = 'Aa Ee Ii Oo Uu' * factor      # no accents / diacritic marks


benchmark( str1 )
puts "------------"
benchmark( str2 )



__END__

##
# note: for testing comment/uncomment __END__

#
#  try different locale / culture mapping

UNACCENT_DE_BASIC = {
  'Ä'=>'AE',  'ä'=>'ae',
  'Ö'=>'OE',  'ö'=>'oe',
              'ß'=>'ss',
  'Ü'=>'UE',  'ü'=>'ue',
}
UNACCENT_DE = UNACCENT.merge( UNACCENT_DE_BASIC)

# benchmark( str1, UNACCENT_DE )
# puts "------------"
# benchmark( str2, UNACCENT_DE )


#
# try / test unaccent functions

require 'pp'

pp unaccent_each_char( str1, UNACCENT )
pp unaccent_each_char( str1, UNACCENT_DE )

pp unaccent_each_char_v2( str1, UNACCENT )
pp unaccent_each_char_v2( str1, UNACCENT_DE )

pp unaccent_each_char_reduce( str1, UNACCENT )
pp unaccent_each_char_reduce( str1, UNACCENT_DE )

pp unaccent_each_char_reduce_v2( str1, UNACCENT )
pp unaccent_each_char_reduce_v2( str1, UNACCENT_DE )

pp unaccent_gsub( str1, UNACCENT )
pp unaccent_gsub( str1, UNACCENT_DE )

pp unaccent_gsub_v2( str1, UNACCENT )
pp unaccent_gsub_v2( str1, UNACCENT_DE )

pp unaccent_gsub_v3( str1, UNACCENT )
pp unaccent_gsub_v3( str1, UNACCENT_DE )

pp unaccent_scan( str1, UNACCENT )
pp unaccent_scan( str1, UNACCENT_DE )
