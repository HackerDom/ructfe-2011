#!/usr/bin/ruby1.9.1
# coding: utf-8

require 'json'
require 'curb'
require 'fileutils'

$command,$ip = ARGV[0..1]

$status =   {
  'OK' => 101,
  'NO_FLAG' => 102,
  'MUMBLE' => 103,
  'DOWN' => 104,
  'INTERNAL_ERROR' => 110
}

def OK(msg)
  print $print_str
  $stderr.puts msg
  exit $status['OK']
end

def NO_FLAG(msg)
  $stderr.puts msg
  exit $status['NO_FLAG']
end

def MUMBLE(msg)
  $stderr.puts msg
  exit $status['MUMBLE']
end

def DOWN(msg)
  $stderr.puts msg
  exit $status['DOWN']
end

def INTERNAL_ERROR(msg)
  $stderr.puts msg
  exit $status['INTERNAL_ERROR']
end

def RandomString(length)
  return (0...length).map{ ('a'..'z').to_a[rand(26)] }.join
end

def make_put()  
  id, flag = ARGV[2..3]
  pass = RandomString(15)

  testCase = rand(3)

  $print_str = "#{id}_#{testCase}_#{pass}"
  case testCase
    when 0      
      put_1(id,flag)
    when 1
      put_2(id,flag,pass)
    when 2
      put_3(id,flag,pass)
  end

end

def make_get()
  id, flag = ARGV[2..3]  
  id,testCase,pass = id.split("_")

  case testCase
    when "0"
      get_1(id,flag)
    when "1"
      get_2(id,flag,pass)
    when "2"
      get_3(id,flag,pass)
  end
end


def put_2(id,flag,pass)
  begin
    jsonData =  Curl::Easy.http_post("http://" + $ip + ":82/auth",
          Curl::PostField.content('action','register'),
          Curl::PostField.content('username',id),
          Curl::PostField.content('password',pass),
          Curl::PostField.content('password_again',pass)
    ).body_str

    result = JSON.parse(jsonData)
    case result['result']
      when "Ok"

      else 
        MUMBLE("")
    end
    c =  Curl::Easy.http_post("http://" + $ip + ":82/auth",
          Curl::PostField.content('action','login'),
          Curl::PostField.content('username',id),
          Curl::PostField.content('password',pass)
    )
    result = JSON.parse(c.body_str)
    case result['result']
      when "Ok"

      else 
        MUMBLE("")
    end
    if (c.header_str =~ /(id=[a-z]+)/m)
      id = $1
    else
      MUMBLE("")
    end
    c = Curl::Easy.new("http://" + $ip + ":82/music");
    c.cookies = id
    c.http_post(
          Curl::PostField.content('action','createplaylist'),
          Curl::PostField.content('name',flag),
          Curl::PostField.content('share','private')
    )
    result = JSON.parse(c.body_str)
    case result['result']
      when "Ok"
        OK("")
      else 
        MUMBLE("")
    end

  rescue  Curl::Err::ConnectionFailedError => e
    DOWN(e)
  rescue JSON::ParserError => e
    MUMBLE("")
  end
end

def get_2(id,flag,pass)
  begin
    c =  Curl::Easy.http_post("http://" + $ip + ":82/auth",
          Curl::PostField.content('action','login'),
          Curl::PostField.content('username',id),
          Curl::PostField.content('password',pass)
    )
    result = JSON.parse(c.body_str)
    case result['result']
      when "Ok"

      else 
        MUMBLE("")
    end
    if (c.header_str =~ /(id=[a-z]+)/m)
      id = $1
    else
      MUMBLE("")
    end
    
    c = Curl::Easy.new("http://" + $ip + ":82/music");
    c.cookies = id
    c.http_post(
          Curl::PostField.content('action','playlists')
    )
    result = JSON.parse(c.body_str)
    result['playlists'].each{ |playlist| 
      if ( playlist['name'] == flag )
        OK("")
      end
    }
    NO_FLAG("")
  rescue  Curl::Err::ConnectionFailedError => e
    DOWN(e)
  rescue JSON::ParserError => e
    MUMBLE("")
  end
end

def put_3(id,flag,pass)
  begin
    jsonData =  Curl::Easy.http_post("http://" + $ip + ":82/auth",
          Curl::PostField.content('action','register'),
          Curl::PostField.content('username',id),
          Curl::PostField.content('password',pass),
          Curl::PostField.content('password_again',pass)
    ).body_str

    result = JSON.parse(jsonData)
    case result['result']
      when "Ok"

      else 
        MUMBLE("")
    end
    c =  Curl::Easy.http_post("http://" + $ip + ":82/auth",
          Curl::PostField.content('action','login'),
          Curl::PostField.content('username',id),
          Curl::PostField.content('password',pass)
    )
    result = JSON.parse(c.body_str)
    case result['result']
      when "Ok"

      else 
        MUMBLE("")
    end
    if (c.header_str =~ /(id=[a-z]+)/m)
      id = $1
    else
      MUMBLE("")
    end


    flag.each_char{ |chr|
      if ( chr != '=')
        c = Curl::Easy.new("http://" + $ip + ":82/music");
        c.cookies = id
        c.http_post(
              Curl::PostField.content('action','addsong'),
              Curl::PostField.content('playlist','default'),
              Curl::PostField.content('song',chr.to_s + '.mp3')
          )
        result = JSON.parse(c.body_str)
        case result['result']
          when "Ok"
    
          else 
            MUMBLE("")
        end
        sleep 0.1
      end
    }
    OK("")
  rescue  Curl::Err::ConnectionFailedError => e
    DOWN(e)
  rescue JSON::ParserError => e
    MUMBLE("")
  end
end

def get_3(id,flag,pass)
  begin
    c =  Curl::Easy.http_post("http://" + $ip + ":82/auth",
          Curl::PostField.content('action','login'),
          Curl::PostField.content('username',id),
          Curl::PostField.content('password',pass)
    )
    result = JSON.parse(c.body_str)
    case result['result']
      when "Ok"

      else 
        MUMBLE("")
    end
    if (c.header_str =~ /(id=[a-z]+)/m)
      id = $1
    else
      MUMBLE("")
    end
    
    c = Curl::Easy.new("http://" + $ip + ":82/music");
    c.cookies = id
    c.http_post(
          Curl::PostField.content('action','loadplaylist'),
          Curl::PostField.content('name','default')
    )
    result = JSON.parse(c.body_str)
    getflag = ''
    result['songs'].each{ |song| 
      getflag += song['name'][0]
    }
    getflag += '='
    if ( getflag == flag )
      OK("")
    else
      NO_FLAG("")
    end
  rescue  Curl::Err::ConnectionFailedError => e
    DOWN(e)
  rescue JSON::ParserError => e
    MUMBLE("")
  end
end

def put_1(id,flag)
  begin
    jsonData =  Curl::Easy.http_post("http://" + $ip + ":82/auth",
          Curl::PostField.content('action','register'),
          Curl::PostField.content('username',id),
          Curl::PostField.content('password',flag),
          Curl::PostField.content('password_again',flag)
    ).body_str

    result = JSON.parse(jsonData)
    case result['result']
      when "Ok"
        OK("")
      else 
        MUMBLE("")
    end
  rescue  Curl::Err::ConnectionFailedError => e
    DOWN(e)
  rescue JSON::ParserError => e
    MUMBLE("")
  end
end

def get_1(id,flag)
  begin  
    c =  Curl::Easy.http_post("http://" + $ip + ":82/auth",
          Curl::PostField.content('action','login'),
          Curl::PostField.content('username',id),
          Curl::PostField.content('password',flag)
    )
    result = JSON.parse(c.body_str)
    case result['result']
      when "Ok"
        OK("")
      else 
        MUMBLE("")
    end
  rescue  Curl::Err::ConnectionFailedError => e
    DOWN(e)
  rescue JSON::ParserError => e
    MUMBLE("")
  end
end

def make_check()
  id = RandomString(15)
  pass = RandomString(15)
  begin
    jsonData =  Curl::Easy.http_post("http://" + $ip + ":82/auth",
          Curl::PostField.content('action','register'),
          Curl::PostField.content('username',id),
          Curl::PostField.content('password',pass),
          Curl::PostField.content('password_again',pass)
    ).body_str

    result = JSON.parse(jsonData)
    case result['result']
      when "Ok"

      else 
        MUMBLE("")
    end

    c =  Curl::Easy.http_post("http://" + $ip + ":82/auth",
          Curl::PostField.content('action','login'),
          Curl::PostField.content('username',id),
          Curl::PostField.content('password',RandomString(15))
    )
    result = JSON.parse(c.body_str)
    case result['result']
      when "Wrong password"

      else 
        MUMBLE("")
    end

    c =  Curl::Easy.http_post("http://" + $ip + ":82/auth",
          Curl::PostField.content('action','login'),
          Curl::PostField.content('username',id),
          Curl::PostField.content('password',pass)
    )

    if (c.header_str =~ /(id=[a-z]+)/m)
      cookie_id = $1
    else
      MUMBLE("")
    end

    result = JSON.parse(c.body_str)
    case result['result']
      when "Ok"

      else 
        MUMBLE("")
    end
    
    
    c =  Curl::Easy.http_post("http://" + $ip + ":82/music",
          Curl::PostField.content('action','users')
    )
    
    result = JSON.parse(c.body_str)

    ok = false
    result['users'].each { |user|
      if ( user['name'] == id )
        ok = true
      end
    }

    if ( ok == false )
      MUMBLE("")
    end

    public_playlist = RandomString(30)
    private_playlist = RandomString(30)

    c = Curl::Easy.new("http://" + $ip + ":82/music");
    c.cookies = cookie_id
    c.http_post(
          Curl::PostField.content('action','createplaylist'),
          Curl::PostField.content('name',private_playlist),
          Curl::PostField.content('share','private')
    )
    result = JSON.parse(c.body_str)
    case result['result']
      when "Ok"

      else 
        MUMBLE("")
    end
    
    c = Curl::Easy.new("http://" + $ip + ":82/search");
    c.cookies = cookie_id
    c.http_post(
          Curl::PostField.content('text',private_playlist)
    )
    result = JSON.parse(c.body_str)
    case result['search']
      when ""

      else
        MUMBLE("")
    end

    c = Curl::Easy.new("http://" + $ip + ":82/music");
    c.cookies = cookie_id
    c.http_post(
          Curl::PostField.content('action','createplaylist'),
          Curl::PostField.content('name',public_playlist),
          Curl::PostField.content('share','public')
    )
    result = JSON.parse(c.body_str)
    case result['result']
      when "Ok"

      else 
        MUMBLE("")
    end
    
    c = Curl::Easy.new("http://" + $ip + ":82/search");
    c.cookies = cookie_id
    c.http_post(
          Curl::PostField.content('text',public_playlist)
    )
    result = JSON.parse(c.body_str)
    case result['search'][0]['name']
      when "#{id} #{public_playlist}"

      else
        MUMBLE("")
    end

    OK("")
  rescue  Curl::Err::ConnectionFailedError => e
    DOWN(e)
  rescue JSON::ParserError => e
    MUMBLE("")
  end
end

case $command
  when "check"
    make_check()
  when "put"
    make_put()
  when "get"
    make_get()
  else
    INTERNAL_ERROR("Invalid arguments")
end
