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
    @state.to_s
  end
end

class Board
  include Comparable

  attr_accessor :board, :rows, :cols, :parts

  def initialize rows, cols
    @rows, @cols = rows, cols
    @parts_num = 2 + rand(rows)
    @parts = []
    @board = Array.new(@rows) { Array.new(@cols) { " " } }
    p @board
    generate_random_board
  end

  def <=>(another_board)
    require 'set'
    if @parts.to_set == another_board.parts.to_set
      0
    else
      1
    end
  end

  def generate_random_board

    for i in (0...@rows)
      for j in (0...@cols)
        arr = [" ", " ", " ", :X, Part.new(i, j, self)] # possible things to be place in a cell
        obj = arr[rand(arr.length)] # choose one of them at random
        if obj.is_a? Part
          @parts << obj
        end
        @board[i][j] = obj
      end
    end

    p @board
  end

  def to_s
    puts 'rows: ' + @rows.to_s
    puts 'cols: ' + @cols.to_s
    puts " _"*@cols

    for i in (0...@rows)
      print '|'
      print @board[i].join ' '
      print "|\n"
    end
    puts " -"*@cols
    @parts.each_with_index do |p, i|
      puts "Part #{i}: "+p.position.join(" , ")
    end
  end
end

class Part
  include Comparable

  attr_accessor :position, :board

  def initialize x, y, board
    @position = [x,y]
    @board = board
  end

  def set_board board
    @board = board
  end

  def move_nxt pt, pos # moves the part to the next position (pt) if it can be moved
    x, y = pt
    if x == @board.rows || x == -1 || y == @board.cols || y == -1
      return -1 # I would colide if I continue, I shouldn't move!
    elsif @board.board[x][y] == :X
      return 1 # I hit an obstacle
    elsif @board.board[x][y].is_a? Part
      #puts 'here'
      @board.board[@position[0]][@position[1]] = " "
      @board.parts.delete self
      #p @board.board
      return 2 # I ran into another part, make us one!
    else
      #puts 'herrrr'
      #puts "#{@position[0]}  #{position[1]}"
      @board.board[pos[0]][pos[1]] = " "#.delete_at(@position[1])#.insert(@position[1], " ")     
      #puts "#{x}  #{y}"
      @board.board[x][y] = self
      #@position = [x, y]
      move_nxt
      return 3
    end     
  end

  def <=>(another_part)
    if @position == another_part.position
      0
    else
      1
    end
  end

  def can_move pos
    x, y = pos
    puts "POS: #{pos}"
    if x == @board.rows || x == -1 || y == @board.cols || y == -1
      return -1
    elsif @board.board[x][y].is_a? Part
      @board.parts.delete self
      return 2
    elsif @board.board[x][y] == :X
      return 1
    else
      return 3
    end
  end

  def move direction
    nxt = @position
    x, y = @position
    @board.board[x][y] = " "
    case direction
    when :N
      begin
        curr = nxt
        nxt = [nxt[0] - 1, nxt[1]]
        cont = can_move nxt
      end while cont == 3
      if cont != -1
        @position = curr
      end
    when :S
      begin
        curr = nxt
        nxt = [nxt[0] + 1, nxt[1]]
        cont = can_move nxt
      end while cont == 3
      if cont != -1
        @position = curr
      end
    when :E
      begin
        curr = nxt
        nxt = [nxt[0], nxt[1] + 1]
        cont = can_move nxt
      end while cont == 3
      if cont != -1
        @position = curr
      end
    when :W
      begin
        curr = nxt
        nxt = [nxt[0], nxt[1] - 1]
        cont = can_move nxt
      end while cont == 3
      if cont != -1
        @position = curr
      end
    end
    x, y = @position
    @board.board[x][y] = self

    if cont == -1
      return -1
    end
  end

  def move_N
    begin  #do while
      nxt = [@position[0]-1, @position[1]] # 1 step north
      x = move_nxt nxt, @position # check this step and try to move
    end while x == 3 # as long as I can still move, then move
    x
  end

  def move_S
    begin  #do while
      nxt = [@position[0]+1, @position[1]] # 1 step south
      x = move_nxt nxt, @position # check this step and try to move
    end while x == 3 # as long as I can still move, then move
    x
  end

  def move_E
    begin  #do while
      nxt = [@position[0], @position[1]+1] # 1 step east
      x = move_nxt nxt, @position # check this step and try to move
    end while x == 3 # as long as I can still move, then move
    x
  end

  def move_W
    begin  #do while
      nxt = [@position[0], @position[1]-1] # 1 step west
      x = move_nxt nxt, @position # check this step and try to move
    end while x == 3 # as long as I can still move, then move
    x
  end

  def to_s
    "O"
  end
end

class Problem

  attr_accessor :operators, :init_state, :state_space

  def initialize board
    @board = board
    @operators = [:N, :E, :W, :S]
    @init_state = @board.clone
    @state_space = []
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

  require 'set'

  def initialize problem, strategy=:BF
    @problem = problem
    @strategy = strategy
    @nodes = Set.new
    solution = solve
    puts '---------------Solution-------------'
    puts solution
  end

  def solve
    node = Node.new @problem.init_state, nil, nil, 0, 0
    @nodes << node

    begin
      
      node = @nodes.first
      @nodes.delete @nodes.first
      
      if @problem.goal_test node.state
        return node
      end

      puts "node count before: #{@nodes.count}"

      @nodes = queue(@nodes, expand(node, @problem))

      puts "node count: #{@nodes.count}"

    end while !@nodes.empty?
    return false
  end

  def queue nodes, expanded
    case @strategy
    when :BF
      return (nodes.to_set + expanded.to_set).to_a
    end

  end

  def expand node, problem
    state = node.state#.clone
          puts "*-"*30
          puts state
          puts "*-"*30
    parts = state.parts
    nodes = Set.new
    new_node = nil
    parts.each do |p|
      problem.operators.each do |op|
        state = state.clone
        result = p.move op#.send('move_' + o.to_s)
        puts "result: #{result} .. #{p.position} .. #{op}"
        if result != -1
          new_node = Node.new(state, node.state, op, node.depth + 1, node.path_cost + 1)
          nodes << new_node
        end
      end
    end
    nodes
  end
  #   x = @board.parts.first.send('move_E')#.move_E
  #   puts '---------------------'
  #   puts @board
  #   puts x
  #   puts @board.parts.length
  # end
end

class Solver

  def initialize
    @board = Board.new (2+rand(4)), (2+rand(4))
    b2 = @board.clone
    @problem = Problem.new @board
    Search.new @problem
    puts @board == b2
  end
end

Solver.new