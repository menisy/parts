class Node
  
  include Comparable

  attr_accessor :state, :parent, :operator, :depth, :path_cost

  def initialize state, parent, operator, depth, path_cost
    @state, @parent, @operator, @depth, @path_cost = state, parent, operator, depth, path_cost
  end

  def <=>(another_node)
    if @state == another_node.state && @parent == another_node.parent && @operator == another_node.operator && @depth == another_node.depth && @path_cost == another_node.path_cost
      0
    else
      1
    end
  end

  def to_s
    s = @state.to_s
    s += "\n\nDepth: #{@depth}\n\nCost: #{@path_cost}\n\nOperator: #{@operator}"
  end
end

class Board
  include Comparable

  attr_accessor :board, :rows, :cols, :parts

  def initialize rows, cols, file_name=nil
    @parts = []
    unless file_name
      @rows, @cols = rows, cols
      @board = Array.new(@rows) { Array.new(@cols) { " " } }
      generate_random_board
    else
      generate_board_from_file file_name
    end

    assemble_parts
  end

  # Returns the next point from point "pt" given the direction "dir"
  def next_point pt, dir
    r, c = pt
    case dir
    when :N
      [r - 1, c]
    when :E
      [r, c + 1]
    when :W
      [r, c - 1]
    when :S
      [r + 1, c]
    end
  end

  def generate_board_from_file file_name

    @board = Array.new
    r, c = 0, 0
    parts_count = 0
    File.open("#{file_name}.txt", "r").each_line do |line|
      @board << Array.new
      c = 0
      for char in line.split ""
        case char
        when 'O'
          @board[r][c] = Part.new r, c, self, parts_count
          parts_count += 1
          @parts << @board[r][c]
        when "\n"
          next
        else
          @board[r][c] = char
        end
        c+=1
      end
      r += 1
    end
    @rows, @cols = r, c
  end

  def <=>(another_board)
    if @parts == another_board.parts
      0
    else
      1
    end
  end

  # Assembles all the parts in the board who are neighboring each other
  def assemble_parts
    begin
      changes = 0
      @parts.each do |part|
        part.positions.each do |pos|
          around = around pos
          around.each do |cell|
            r, c = cell
            if @board[r][c].is_a?(Part) && @board[r][c] != part
              changes += 1
              other_part = @board[r][c]
              part.positions = part.positions + other_part.positions
              @board[r][c] = part
              self.parts.delete other_part
              update_positions
            end
          end
        end
      end
    end while changes > 0
  end

  # Returns an array of the valid cells (max 4) around the given pt
  def around pt
    points = [:N, :E, :W, :S].map{ |d| next_point(pt, d) }
    pts = []
    # remove invalid points
    points.each do |point|
      r, c = point
      if ! (r == -1 || r == @rows || c == -1 || c == @cols)
        pts << point
      end
    end
    # puts "Pointssssssssssssssssss"
    # puts points
    pts
  end

  def update_positions
    # Remove existing parts from board array
    for i in (0...@rows)
      for j in (0...@cols)
        if @board[i][j].is_a? Part
          @board[i][j] = " "
        end
      end
    end

    # Place again the current parts with their new positions!
    for part in @parts
      for pos in part.positions
        r, c = pos
        @board[r][c] = part
      end
    end
  end

  def generate_random_board
    parts_count = 0
    for i in (0...@rows)
      for j in (0...@cols)
        arr = [" ", " ", " ", "X", Part.new(i, j, self, parts_count)] #possible things to be place in a cell
        obj = arr[rand(arr.length)] # choose one of them at random
        if obj.is_a? Part
          @parts << obj
          parts_count += 1
        end
        @board[i][j] = obj
      end
    end
    p @board
  end

  def to_s
    puts " _"*@cols

    for i in (0...@rows)
      print '|'
      print @board[i].join ' '
      print "|\n"
    end
    puts " -"*@cols
    # @parts.each_with_index do |p, i|
    #   #puts "Part #{i}: "
    #   p.positions.each do |pos|
    #     #puts pos.join(" , ")
    #   end
    # end
    ""
  end
end

class Part
  include Comparable

  require 'set'

  attr_accessor :positions, :board

  def initialize x, y, board, index
    @positions = Set.new
    @positions << [x,y]
    @board, @index = board, index
  end

  def set_board board
    @board = board
  end


  def <=>(another_part)
    if @positions == another_part.positions
      0
    else
      1
    end
  end


  # Actually moves the part and returns the cost of movement
  def move steps, dir

    # count the positions to be moved first
    positions = @positions
    parts_count = positions.count

    # move the positions (steps) number of times
    steps.times{ @positions = (@positions.map{ |i| next_point(i, dir) }).to_set }

    # update the board now that you moved the parts
    @board.update_positions

    # check all cells around the new positions, if parts exist, connect them!
    @board.assemble_parts

    # update the board now that you assembled the parts
    @board.update_positions

    return parts_count * steps
  end

  # Checks if the part can move in this direction or not returning number of moves
  def can_move dir
    moves = 0

    # Create a shallow copy of my positions
    positions = @positions

    # Move this shallow copy untill something stops it
    begin
      next_positions = positions.map{ |i| next_point(i, dir) }

      checks = next_positions.map { |i| check_point i }
   
      if checks.index('dead')
        return -1
      end

      unless (checks & %w(obst part)).any?
        positions = next_positions
        moves += 1
      else
        return moves
      end
    end while true
  end

  # Returns a string representing the status of the given "pt" on the board
  def check_point pt

    r, c = pt

    # Out of bounds, barbbed wire, you're DEAD pal!
    if r == -1 || r == @board.rows || c == -1 || c == @board.cols
      return "dead"
    # Can't pass through, obstacle in my way
    elsif @board.board[r][c] == "X"
      return "obst"
    # Looks like another part which is not a part of me..yet!
    elsif @board.board[r][c].is_a?(Part) && @board.board[r][c] != self
      return "part"
    else
      return "clear"
    end      
  end

  # Returns the next point from point "pt" given the direction "dir"
  def next_point pt, dir
    r, c = pt
    case dir
    when :N
      [r - 1, c]
    when :E
      [r, c + 1]
    when :W
      [r, c - 1]
    when :S
      [r + 1, c]
    end
  end

  def to_s
    @index.to_s
  end
end

class Problem

  attr_accessor :operators, :init_state, :state_space

  def initialize board
    @board = board
    @init_state = Marshal::load(Marshal.dump(@board))
    @state_space = []
  end

  def self.operators state
    ops = []
    dirs = [:N, :E, :S, :W]
    state.parts.each do |part|
      dirs.each do |direction|
        ops << [part, direction]
      end
    end
    ops
  end

  def goal_test state
    if state.parts.count == 1
      true
    else
      false
    end
  end

  def path_cost nodes
    #TODO total cost of nodes
  end
end

class Search

  attr_accessor :board, :problem, :nodes

  def initialize problem, strategy=:BF
    @problem = problem
    @strategy = strategy
    @nodes = []
    if @strategy == :ID
      solution = solve_id
    else
      solution = solve
    end
    puts '---------------Solution-------------'
    puts solution
  end


  # Solves with iterative deepening strategy
  def solve_id
    depth = 0

    while true
      node = Node.new Marshal::load(Marshal.dump(@problem.init_state)), nil, nil, 0, 0
      @nodes << node

      begin
        
        node = @nodes.first
        @nodes = @nodes - [node]

        print_node node
        
        if @problem.goal_test node.state
          return node
        end

        @nodes = Search.expand(node) + @nodes

        break if @nodes.empty?

      end while node.depth <= depth
      depth += 1
      break if @nodes.empty?
    end
    return false
  end

  def solve
    node = Node.new @problem.init_state, nil, nil, 0, 0
    @nodes << node

    begin
      
      node = @nodes.first
      @nodes.delete node

      print_node node
      
      if @problem.goal_test node.state
        return node
      end

      @nodes = queue(@nodes, Search.expand(node))

    end while !@nodes.empty?
    return false
  end

  def print_node node
    puts "\n\n\n\n"
    puts "Node to be Expanded"
    puts "Parent"
    puts node.parent
    puts "Node"
    puts node
    puts "Nodes count: #{@nodes.count}"
    puts "\n\n\n\n"
    puts "==============================================="
  end

  def queue nodes, expanded
    case @strategy
    when :BF
      return nodes + expanded
    when :DF
      return expanded + nodes
    end

  end

  def self.expand node
    state = Marshal::load(Marshal.dump(node.state))
    nodes = []

    Problem.operators(state).each do |op|
      part, dir = op
      part = Marshal::load(Marshal.dump(part))
      can_move = part.can_move dir
      cost = 0
      if can_move > 0
        cost = part.move can_move, dir
      end
      if cost > 0
        new_node = Node.new(part.board, node, op, node.depth + 1, node.path_cost + cost)
        nodes << new_node
      end
    end
    nodes
  end
end

class Solver

  attr_accessor :problem, :board, :search

  def initialize file_name=nil, strategy=nil
    @board = Board.new (2+rand(4)), (2+rand(4)), file_name
    @problem = Problem.new @board
    @search = Search.new @problem, strategy
  end
end

#@solver = Solver.new 'test_ad'
@solver = Solver.new 'test4', :ID