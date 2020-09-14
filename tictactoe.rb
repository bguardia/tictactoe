require 'pry'

=begin
Graphic 
Packages array and or strings as an image to be stored in Printer
=end

class Graphic

  attr_reader :width, :height, :image, :current_state
  attr_reader :padding, :padding_left, :padding_right, :padding_top, :padding_bottom

  DEFAULT_BORDER = " "

  def initialize(args)
    @insertions = []

    #Padding
    @padding = args.fetch(:padding, 0)
    @padding_left = args.fetch(:padding_left, @padding)
    @padding_right = args.fetch(:padding_right, @padding)
    @padding_top = args.fetch(:padding_top, @padding)
    @padding_bottom = args.fetch(:padding_bottom, @padding)

    #Dimensions
    @width = args.fetch(:width) { get_width(args[:image]) } + @padding_left + @padding_right
    @height = args.fetch(:height) { get_height(args[:image]) } + @padding_top + @padding_bottom
    
    #Image cleaning, generation
    @image = get_image(args)

    set_current_state(@image)    
  end

  def set_current_state (arr)
    @current_state = Marshal.load(Marshal.dump(arr))
  end

  private

  def defaults
    { :char => "I", 
      :padding => 0 }
  end
  
  def self.generate_checkerboard(bg, check_one, check_two, num_rows, num_cols, line_width)
    r = 0
    c = 0

    check_w = check_one.width
    check_h = check_one.height

    num_rows.times do 
      num_cols.times do
          y = r * (check_h + line_width)
          x = c * (check_w + line_width)
          
          if (r + c) % 2 == 0
            check = check_one
          else
            check = check_two
          end
          
          bg.insert(check, x, y) 

          c += 1
      end
      r += 1
      c = 0
    end
  end

  def get_image(args) #Clean up input into the form of an array
    if args.fetch(:image, false) && args[:image].class == String
      arr = string_to_array(args[:image])
    else
      arr =  generate_image(args)
    end     
    
    apply_padding(arr)

    return arr
  end

  def depth(array)
    array.to_a == array.flatten(1) ? 1 : depth(array.flatten(1)) + 1
  end
 
  def get_height(item)
    case item.class.to_s
    when "Graphic"
      item.height
    when "Array"
      item.length
    when "String"
      item.split("\n").length
    else
      1
    end
  end

  def get_width(item)
    case item.class.to_s
    when "Graphic"
      item.width
    when "Array"
      get_arr_width(item)
    when "String"
      get_arr_width(item.split("\n"))
    else
      item.to_s.length
    end
  end
  
  def get_arr_width(arr)
    width = arr.reduce(0) do |w,v|  #Find longest array or string within the array
         next w unless v.class == Array || v.class  == String
         if v.length > w
           v.length
         else
           w
         end
       end
  end

  public

  def self.checkerboard(args)
    bg_char = args.fetch(:char)
    char_a = args.fetch(:char_a, " ")
    char_b = args.fetch(:char_b, char_a)

    num_cols = args.fetch(:num_cols, 3)
    num_rows = args.fetch(:num_rows, num_cols)

    line_width = args.fetch(:padding, 0)

    width = num_cols * args[:check_w] + line_width * (num_cols - 1)
    height = num_rows * args[:check_h] + line_width * (num_rows - 1)

    bg_graphic = self.new(char: bg_char, width: width, height: height, padding: 0)

    check_one = self.new(char: char_a, width: args[:check_w], height: args[:check_h], padding: 0)
    check_two = self.new(char: char_b, width: args[:check_w], height: args[:check_h], padding: 0)

    generate_checkerboard(bg_graphic, check_one, check_two, num_rows, num_cols, line_width)

    #bg_graphic.insertions.clear
    bg_graphic.merge_with_current
    
    return bg_graphic
  end

  def generate_image(args) #Generates a 2D array from given parameters (:char to repeate for :width x :height)
    char = args[:char].to_s
    width = args[:width]
    height = args[:height]
    
    str = (char * width + "\n") * height

    arr = string_to_array(str)  
  end
  
  def apply_padding(arr) #Wrapper for apply_border to feed it padding properties
    apply_border(arr: arr,
                 top: padding_top,
                 bottom: padding_bottom,
                 left: padding_left,
                 right: padding_right)
  end

  def apply_border(args) #Applies a border to 2D array
    arr = args.fetch(:arr)

    width = args.fetch(:width, false) || get_width(args[:arr])
    height = args.fetch(:height, false) || get_height(args[:arr])

    top = args.fetch(:top, 0)
    bottom = args.fetch(:bottom, 0)
    left = args.fetch(:left, 0)
    right = args.fetch(:right, 0)

    width += left + right

    border_char = args.fetch(:char, DEFAULT_BORDER)

    horizontal_border = (border_char * width).split('')
    vertical_border_left = (border_char * left)
    vertical_border_right = (border_char * right)

    arr.each_index do |i|
      arr[i] = (vertical_border_left + arr[i].join + vertical_border_right).split('')
    end
   
    top.times do
      arr.unshift(horizontal_border)
    end

    bottom.times do
      arr.push(horizontal_border)
    end
  end

  def string_to_array(str, by_char = true) #Split a string into an array by line (by_char = false) or into a 2D array by char (by_char = true)
    arr = str.split("\n")
   
    if by_char
    arr.map! do |v|
      v.split('')
    end
    end
  end

  def array_to_string(arr)
    arr.reduce("") do |str, val|
      if val.class == Array
        val = val.join
      end

      str += val + "\n"
    end
  end

  public 
  
  def insertions #Insertions keep track of additions to graphic
    @insertions
  end
  
  def add_insertion(item, pos_x, pos_y, width, height)
    @insertions.push({ :graphic => item,
                       :pos_x => pos_x,
                       :pos_y => pos_y,
                       :width => width, 
                       :height => height })
  end
  
  def return_insertion_points
    insertions.reduce([]) do |a,v|
      pos_x = v[:pos_x]
      pos_y = v[:pos_y]

      a.push([pos_x, pos_y])
    end
  end

  def remove_insertion_at(index)
    @insertions.slice!(index)
  end

  def remove_insertion_graphic(insert_hash)
    graphic = self.image
    combine_with_arr(graphic, insert_hash[:pos_x], insert_hash[:pos_y], insert_hash[:width], insert_hash[:height])
  end

  def place_insertion(insert_hash)
    combine_with_arr(insert_hash[:graphic], insert_hash[:pos_x], insert_hash[:pos_y], insert_hash[:width], insert_hash[:height])
  end

  def merge_with_current
    @image = Marshal.load(Marshal.dump(@current_state))
  end

  def clear_insertions
    insertions.clear
  end

  def insert(item, pos_x, pos_y)
    width = get_width(item)
    height = get_height(item)
    
    item = item.class == Graphic ? item.image : item
    
    add_insertion(item, pos_x, pos_y, width, height)
    place_insertion(insertions.last)
  end

  def remove(index)
    removal = remove_insertion_at(index)
    remove_insertion_graphic(removal)
  end

  def combine_with_arr(arr, pos_x, pos_y, width, height) 
  for x in 0...width
      for y in 0...height
        a = pos_y + y
        b = pos_x + x
        #puts "a:#{a}, b:#{b}, x:#{x}, y:#{y}"
        break unless self.current_state[a] && self.current_state[a][b]
        self.current_state[a][b] = arr[y][x]
      end
    end
  end

  def restore_original
    clear_insertions
    set_current_state(image)
  end

  def to_s
    self.current_state.reduce("") { |s,v| s += v.class == Array ? v.join + "\n" : v + "\n" } 
  end

end

=begin
Piece class
Keeps track of key and graphic combinations for the game.
=end

class Piece

  @@all = []
  
  attr_reader :key, :graphic

  def initialize(key, graphic)
    @key = key
    @graphic = graphic

    Piece.add(self)
  end
  
  def self.all
    @@all
  end

  def self.add(piece)
    @@all.push(piece) 
  end

  def self.get_graphic(key)
    key.downcase!

    Piece.all.each do |p|
      p if p.key == key
    end
  end
  
  def self.get_graphic_at(index)
    @@all[index].graphic
  end

  def to_s
    key.upcase
  end
end

=begin
Board class
Handles interactions between the board graphic and game pieces
=end

class Board

  def initialize(args={})
    args = default.merge(args)

    @num_rows = args[:num_rows]
    @num_cols = args[:num_cols]
    @graphic = Graphic.checkerboard(char: args[:char], 
                                    char_a: " ", 
                                    check_w: args[:check_w], 
                                    check_h: args[:check_h], 
                                    padding: args[:padding], 
                                    num_cols: @num_cols, 
                                    num_rows: @num_rows)
    @arr = create_arr 
    @space_coords = @graphic.return_insertion_points
    label_spaces
  end

  def default
    { :char => "I",
      :num_cols => 3,
      :num_rows => 3,
      :check_w => 10,
      :check_h => 5,
      :padding => 1
    }
  end

  def label_spaces
    n = 0
    offset = 1
    
    (@num_cols * @num_rows).times do
      coords = space_coords[n]
      pos_x = coords[0] + offset
      pos_y = coords[1] + offset
      label = n + 1
      @graphic.insert(label.to_s, pos_x, pos_y)
      n += 1
    end
  end

  def arr
    @arr
  end
  
  def create_arr
    Array.new(@num_rows) { Array.new(@num_cols, " ") }  
  end

  def reset_arr
    @arr = create_arr
  end

  def get_arr_val_at(index)
    r = index / arr[0].length
    c = index - r * arr[0].length
    #puts "arr[#{r}][#{c}]: #{arr[r][c]}"
    arr[r][c]
  end

  def to_arr(index, value)
    r = index / arr[0].length
    c = index - r * arr[0].length

    @arr[r][c] = value
  end

  def graphic
    @graphic
  end

  def space_coords
    @space_coords
  end

  def place(index, piece)
    to_arr(index, piece.key)
    coords = space_coords[index]
    graphic.insert(piece.graphic, coords[0], coords[1])
  end

  def full?
    not_full = true  
    self.arr.each do |a|
     not_full = a.any?(" ")     
     break if not_full
    end

    full = !not_full
    return full
  end

  def reset
    self.graphic.restore_original
    label_spaces
    reset_arr
  end  
end

=begin
Screen
Handles arrangement of graphics to be printed to command line
Currently unused

class Screen < Graphic 

  MARGIN_LEFT = 5
  MARGIN_RIGHT = 5
  MARGIN_TOP = 5
  MARGIN_BOTTOM = 5
  
  attr_reader :width, :height, :padding

  def initialize(args={})
    args = defaults.merge(args)
    @num_items = 0
    @items = []
    super
  end

  def defaults
    defaults = { :width => 75,
                 :height => 50,
                 :char => " ",
                 :padding => 0,
                 :insert_padding => 1}
  end

  def insert(item, args)
    pos_x = args.fetch(:pos_x, nil) || get_pos_x(item, args.fetch(:dir, "below"))
    pos_y = args.fetch(:pos_y, nil) || get_pos_y(item, args.fetch(:dir, "below"))

    puts "pos_x: #{pos_x}, pos_y: #{pos_y}"
    super(item, pos_x, pos_y)
  end

  def insertions_exist?
    true if insertions.length != 0 
  end

  def get_pos_x(item, dir)
    width = item.width || get_width(item)
     
    if insertions_exist?
      prev_width = insertions.last[:width]
      x = insertions.last[:pos_x]
     
      case dir
      when "to_left"
        x -= padding + width
      when "to_right"
        x += prev_width
      end
    else
      x = 0
    end
    x
  end

  def get_pos_y(item, dir)
    height = item.height || get_height(item)
    
    if insertions_exist?
      prev_height = insertions.last[:height]
      y = insertions.last[:pos_y]

      case dir
      when "above"
        y -= padding + height
      when "below"
        y += prev_height
      end
    else
      y = 0
    end

    y
  end
end
=end

=begin
Player class
Stores player name, piece and number of wins
=end

class Player
@@numPlayers = 0

  attr_reader :name, :player_num, :piece

  def initialize(name=nil)
    @@numPlayers += 1
    @player_num = @@numPlayers
    @name = name ? name : "Player " + @player_num
    @wins = 0
  end

  def set_piece=(piece)
    @piece = (piece)
  end
 
  def to_s 
    @name  
  end 
end

class Game

  @@total_games = 0
  
  attr_reader :board, :pieces, :players

  def initialize

    @board = get_board
    @pieces = get_pieces
    @players = get_players
    @wins = Hash.new

    @players.each do |p|
      @wins[p] = 0
    end

    self.play
  end
  
  def get_players
    arr = []
    n = 1
    2.times do
       puts "Enter name for Player #{n}:"
       name = gets.chomp
       arr.push(Player.new(name))
       arr.last.set_piece=(self.pieces[n - 1])
       n += 1
    end 
     
    arr 
  end

  def get_board
    Board.new
  end

  def get_wins(player)
    @wins[player]
  end

  def get_pieces
    x_icon = "X    X\n"+
             " X  X \n" +
             "  XX  \n" +
             " X  X \n" +
             "X    X"

    o_icon = "OOOOO\n" +
             "O   O\n" +
             "O   O\n" +
             "O   O\n" +
             "OOOOO\n"

    x_graphic = Graphic.new({:image => x_icon,
                           :padding_left => 2,
                           :padding_right => 2})

    o_graphic = Graphic.new({:image => o_icon,
                           :padding_left => 2,
                           :padding_right => 2 })

    x_piece = Piece.new("x", x_graphic)

    o_piece = Piece.new("o", o_graphic)
    
    return [x_piece, o_piece]
  end

  def play
    n = 0
    win = false
    tie = false
    until win || tie
      player_turn(players[n%2])
      n += 1
      win = meet_win_condition(board.arr)
      tie = board.full?
    end
    puts board.graphic    

    if win
      win_index = (n-1)%2
      winner = players[win_index]
      print_game_results(win: win, winner: winner) 
      @wins[winner] += 1
    else
      print_game_results(win: win)
    end

    @@total_games += 1
   
    if play_again?
      self.restart
      self.play
    else
      puts "Thanks for playing!"
      print_stats
    end
  end

  def print_game_results(args)
    if args[:win]
      print "#{args[:winner]} wins!"
    else
      print "It's a tie!"
    end

    puts " Game Over."

  end

  def print_stats
    puts "Total games: #{@@total_games}"
    puts "#{@players[0].name}'s wins: #{get_wins(@players[0])}"
    puts "#{@players[1].name}'s wins: #{get_wins(@players[1])}"
  end

  def play_again?
    valid_input = false
    until valid_input
      puts "Play again? [y/n]"
      input = gets.chomp.downcase
      if input == "y" || input == "n"
        valid_input = true
      else
        puts "#{input} is not valid. Please type 'y' or 'n'"
      end
    end

    return input == "y"
  end

  def player_turn(player)
    valid_input = false

    puts board.graphic

    while valid_input == false
      puts "#{player}'s turn. Choose where to mark your '#{player.piece}'. [1-9]:"
      target_square = gets.chomp.to_i - 1
      valid_input = is_valid(target_square)
      puts "Input is invalid" unless valid_input
    end

    board.place(target_square, player.piece)
    
  end

  def restart
    board.reset
  end

  def meet_win_condition(arr)

    win = false
    type = ""
    win_indices = []


    #Horizontal wins
    arr.each_index do |i|
      win_indices.clear
      val = nil
      arr.each_index do |j|
        break if arr[i][j] == " "
        val ||= arr[i][j]
        break unless val == arr[i][j]
        win_indices.push(i * arr.length + j)
      end
      if win_indices.length == 3
        win = true
        type = "horizontal"
        break
      end
    end    


    #Diagonal (top left to bottom right)
    unless win
      win_indices.clear
      val = nil
      arr.each_index do |i|
        break if arr[i][i] == " "
        val ||= arr[i][i]
        break unless val == arr[i][i]
        win_indices.push(i * arr.length + i)
      end
      if win_indices.length == 3
        win = true
        type = "diagonal"
      end
    end

    #Diagonal (top right to bottom left)
    unless win
      win_indices.clear
      val = nil
      arr.each_index do |i|
        j = arr.length - (i + 1)
        break if arr[i][j] == " "
        val ||= arr[i][j]
        break unless val == arr[i][j]
        win_indices.push(i * arr.length + j)
      end
      if win_indices.length == 3
        win = true
        type = "diagonal"
      end
    end

    #Vertical wins
    unless win
      arr[0].each_index do |j|
        win_indices.clear
        val = nil
        arr.each_index do |i| 
          #puts "arr[#{i}][#{j}]: #{arr[i][j]}"
          break if arr[i][j] == " "
          val ||= arr[i][j]
          break unless val == arr[i][j]
          win_indices.push(i * arr.length + j)
        end
        if win_indices.length == 3
          win = true
          type = "vertical"
          break
        end
      end
    end 

    if win
      return { :win => win, :type => type, :indices => win_indices }
    else
      false
    end
  end

  def is_valid(input)
    #puts "board.get_arr_val_at(#{input}): #{board.get_arr_val_at(input)}"
    if input >= 0 &&
       input <= 8 &&
       board.get_arr_val_at(input) == " "
      true
    else
      false
    end
  end

end

tic_tac_toe = Game.new
