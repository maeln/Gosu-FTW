# coding: utf-8
# Project1, pour commencer avec Gosu.
# Une suggestion ? Une question ? Un conseil ?
# --> <contact@maeln.com>
# --> Ou sur forum.relite.org

require 'rubygems'
require 'gosu'

class Stars < Gosu::Image
	attr_writer :layer
	attr_reader :y_stars
	
	def initialize(parent, start)
		#-- Class :
		@parent = parent
		
		#-- Images
		@layer = rand(3) + 1 # L'étoiles peut apparaître sur l'un des 3
							 # Calque au hasard.
		@sprite = super(parent, "sprites/stars#{@layer}.png", false)
		
		#-- Variables :
		@x_stars = rand * @parent.width
		# Si la partie vient de commencer, pour remplir l'écran d'étoiles 
		# aléatoirement dans l'espace.
		if start then
			@y_stars = rand * @parent.height
		else
			@y_stars = -50
		end
		@z_stars = 0
	end
	
	def update
		# En fonction du calque, l'étoiles ira plus ou moins vite pour
		# donner une sensation de "profondeur".
		if @layer == 1 then
			@y_stars += 5
			@z_stars = 3
		elsif @layer == 2 then
			@y_stars += 2
			@z_stars = 2
		elsif @layer == 3 then
			@y_stars += 1
			@z_stars = 1
		end
	end
	
	def draw
		super(@x_stars, @y_stars, @z_stars)
	end
end

class Stars_layer
	def initialize(parent)
		#-- Class :
		@parent = parent
		
		#-- Variables :
		@stars = Array.new
		@start = true
	end
	
	def spawn # Pour faire apparaître une étoiles.
		@stars << Stars.new(@parent, @start)
	end
	
	def update
		i = 0
		if @start then # Quand la partie commence on "spawn" aléatoirement
					   # 100 étoiles (WIP).
			100.times do spawn end
			@start = false
		end
		spawn if rand(3) == rand(3) # On fait apparaître des étoiles si 
									# les 2 chiffres aléatoires sont égaux (WIP).
									# Cette méthode est AMHA très moche.
									# Si vous avez une suggestion, merci
									# de me contacter.
		@stars.each do |n|
			n.update
			if n.y_stars >= (@parent.height) then # On supprime l'étoile si elle sort
												  # de la fenêtre.
				@stars.delete_at(i)
			end
			i += 1
		end
	end
	
	def draw
		@stars.each do |n| n.draw end
	end
end		
		
class Enemy < Gosu::Image
	attr_reader :x_enemy, :y_enemy, :life, :sprite
	def initialize(parent)
		#-- Class :
		@window = parent
		
		#-- Images :
		@sprite = super(parent, "sprites/enemy.png", false)
		
		#-- Variables :
		@x_enemy = rand * (@window.width - @sprite.width)
		@y_enemy = -140
		@life = 10
	end
	
	def update
		@y_enemy += 3
		if @life <= 0 then # Si l'ennemi n'a plus de vie, on renvoi un message
						   # Pour que Spaceship le détruit.
			return 3
		end
	end
	
	def damage
		@life -= 1
	end
	
	def contact?(x, y)
		a = (x[0] >= (@x_enemy) && x[0] <= (@x_enemy+@sprite.width)) && (y[0] <= (@y_enemy+@sprite.height) && y[0] >= @y_enemy)
		b = (x[1] >= (@x_enemy) && x[1] <= (@x_enemy+@sprite.width)) && (y[1] <= (@y_enemy+@sprite.height) && y[1] >= @y_enemy)
		c = (x[1] >= (@x_enemy) && x[1] <= (@x_enemy+@sprite.width)) && (y[0] <= (@y_enemy+@sprite.height) && y[0] >= @y_enemy)
		d = (x[0] >= (@x_enemy) && x[0] <= (@x_enemy+@sprite.width)) && (y[1] <= (@y_enemy+@sprite.height) && y[1] >= @y_enemy)
		return a || b || c || d
	end
	
	def draw
		super(@x_enemy, @y_enemy, 6)
	end
end

class Bullet < Gosu::Image
	attr_reader :x_bullet, :y_bullet, :dist
	attr_writer :id # Pour que l'objet Bullet "connaisse" sa place dans l'Array.
	def initialize(parent)
		#-- Class :
		@enemy = parent.enemy
		@spaceship = parent
		
		#-- Images :
		@bullet = super(parent.window, "sprites/blast.png", false)
		
		#-- Variables :
		@y_bullet = @spaceship.y_player
		@x_bullet = @spaceship.x_player + @spaceship.width / 3
		@yreal = [@y_bullet, (@y_bullet+@bullet.height)]
		@xreal = [@x_bullet, (@x_bullet+@bullet.width)]
	end
	
	def update
		@yreal = [@y_bullet, (@y_bullet+@bullet.height)]
		@xreal = [@x_bullet, (@x_bullet+@bullet.width)]
		unless @enemy[0].nil? then
			@enemy.each do |n| # La balle calcule sa distance avec chaque ennemi.
				if n.contact?(@xreal, @yreal) then
					op = @enemy.index(n)
					@spaceship.touch(op, @id)
				end
			end
		end
		if @y_bullet >= 0 then
			@y_bullet -= 10
		else
			@spaceship.bullet_oos(@id) # Si un objet Bullet sort de l'écran
									   # bullet_oos(id_bullet) le détruit.
		end
	end
	
	def draw
		super(@x_bullet, @y_bullet, 4)
	end
end

class Spaceship < Gosu::Image
	attr_reader :x_player, :y_player, :window, :enemy, :life, :nb_bullet, :score
	def initialize(window)
		#-- Class :
		@enemy = Array.new
		
		#-- Images :
		@spaceship = super(window, "sprites/spaceship.png", false)
		
		#-- Variables :
		@x_player = @y_player = 0.0
		@yreal = [@y_player, (@y_player+@spaceship.height)]
		@xreal = [@x_player, (@x_player+@spaceship.width)]
		@bullet = Array.new
		@nb_bullet = 0
		@window = window
		@life = 5
		@time = Gosu::milliseconds/100
		@score = 0
		@white = Gosu::Color.new(255, 255, 255, 255)
	end
	
	def warp(x, y) # Pour télé-porter le joueur n'importe ou.
		@x_player = x
		@y_player = y
	end
	
	#-- Les fonctions qui suivent permette de mettre en mouvement le joueur.
	def move_up
		unless @y_player <= 0
			@y_player -= 4
		end
	end
	
	def move_down
		unless @y_player >= (@window.height-@spaceship.height)
			@y_player += 4
		end
	end
	
	def move_left
		unless @x_player <= 0
			@x_player -= 4
		end
	end
	
	def move_right
		unless @x_player >= (@window.width-@spaceship.width)
			@x_player += 4
		end
	end
	
	def dash_up
		unless @y_player <= 0
			@y_player -= 100
		end
	end
	
	def dash_down
		unless @y_player >= (@window.height-@spaceship.height)
			@y_player += 100
		end
	end
	
	def dash_left
		unless @x_player <= 0
			@x_player -= 100
		end
	end
	
	def dash_right
		unless @x_player >= (@window.width-@spaceship.width)
			@x_player += 100
		end
	end
	#--
	
	def update
		@yreal = [@y_player, (@y_player+@spaceship.height)]
		@xreal = [@x_player, (@x_player+@spaceship.width)]
		@nb_bullet = @bullet.size
		if @life <= 0 then # Si le joueur n'a plus de vie, c'est le Game Over.
			@window.game_over
		else
		
		# Move & Shoot.
		# <!> Note : Impossible d'aller dans 2 direction en même temps
		# ( ex : haut-gauche ) tout en tirant sauf dans le cas de haut-droite.
		# Si vous voyez d'ou vient le bug, merci de me contacter.
		shoot if @window.button_down?(Gosu::Button::KbSpace)
		move_up if @window.button_down?(Gosu::Button::KbUp)
		move_right if @window.button_down?(Gosu::Button::KbRight)
		move_down if @window.button_down?(Gosu::Button::KbDown)
		move_left if @window.button_down?(Gosu::Button::KbLeft)
		
		for i in (0 ... @bullet.size) # Pour "mettre à jour" toute les balles.
			if @bullet[i] then
				@bullet[i].id = i
				shoot = @bullet[i].update
			end
		end
		
		@enemy.each do |n| # De même avec les ennemis.
			unless n.nil?
				# Si le joueur touche l'ennemi, on détruit l'ennemi et
				# On fait perdre une vie au joueur.
				if n.contact?(@xreal, @yreal) then
					@life -= 1
					@enemy.delete_at(@enemy.index(n))
					puts "[Player L] #{@life}"
				# Si l'ennemi n'a plus de vie on le détruit et on incrémente
				# le score de 10.
				elsif n.update == 3 then
					puts "[Dest.]"
					@enemy.delete_at(@enemy.index(n))
					@score += 10
					puts "[Done]"
				# Si l'ennemi sort de la fenêtre, on le détruit et on fait
				# perdre une vie au joueur.
				elsif n.y_enemy >= (@window.height) then
					puts "[En-OOS]"
					@life -= 1
					@enemy.delete_at(@enemy.index(n))
				end
			end
		end
		end
	end
	
	def shoot
		if @time < (Gosu::milliseconds/100) # Cette condition permet de limiter
											# le nombre de tir/seconde.
				@bullet << Bullet.new(self)
				@time = Gosu::milliseconds/100
		end
	end
	
	def touch(nb_enemy, id_bullet) # Lorsqu'une balle touche un ennemi
								   # on supprime la balle et on indique
								   # à l'objet Enemy qu'il à été touché.
		@enemy[nb_enemy].damage
		@bullet.delete_at(id_bullet)
	end
	
	def bullet_oos(id_bullet) # Quand un objet Bullet sort de l'écran on la supprime.
		@bullet.delete_at(id_bullet)
	end
	
	def spawn_enemy
		@enemy << Enemy.new(@window)
	end
	
	def draw
		super(@x_player, @y_player, 5)
		# On dessine tout les objets Bullet et Enemy.
		@bullet.each do |n| n.draw end
		@enemy.each do |n| n.draw end
		@window.draw_line(@x_player - 5, @y_player, @white, @x_player + 5, @y_player, @white, 2)
		@window.draw_line(@x_player, @y_player - 5, @white, @x_player, @y_player + 5, @white, 2)
	end
end

class Director
	def initialize(parent)
		#-- Class :
		@parent = parent
		
		#-- Variables :
		@time = Gosu::milliseconds
		@vitesse = 5000
	end
	
	def update
		if @parent.life > 0 then
			if (@time+@vitesse) < (Gosu::milliseconds) then
				puts "[Spawn] [vit:#{@vitesse}]"
				@parent.spawn_enemy
				@time = Gosu::milliseconds
				if @vitesse > 900 then
					@vitesse -= 100
				end
			end
		end
	end
end

class Game < Gosu::Window
	def initialize
		@x_window = 600
		@y_window = 800
		super(@x_window, @y_window, false)
		self.caption = "Space Des."
		
		#-- Images :
		#nil
		
		#-- Variables :
		#@music = Gosu::Song.new(self, "song/1.mp3")
		@player = Spaceship.new(self)
		@director = Director.new(@player)
		@stars = Stars_layer.new(self)
		@font = Gosu::Font.new(self, "ubuntu-font-family/Ubuntu-B.ttf", 54)
		@hud = Gosu::Font.new(self, "ubuntu-font-family/Ubuntu-R.ttf", 16)
		@game_over = false
		@time = Gosu::milliseconds/50
		@time2 = Gosu::milliseconds/20
		@dash = Gosu::milliseconds
		@dashlock = [false, false, false, false] # Up - Down - Left - Right
		@score = 0
		@score_total = 0
		
		#-- Init :
		@player.warp(@x_window / 2.0, @y_window / 2.0)
		#@music.play(true)
	end
	
	def xor(x, y)
		a = x || y
		b = x && y
		return a && !b
	end
	
	def button_down(id) # On quitte le jeux si le joueur appui sur ESC.
		#@music.stop if id == Gosu::Button::KbEscape
		# Gestion des Dash ( je vais la passer dans la class Player normalement ).
		if not xor(xor(@dashlock[0], @dashlock[1]), xor(@dashlock[2], @dashlock[3])) then
			@dashlock = [false, false, false, false]
		end
		if id == Gosu::Button::KbUp then
			if @dashlock[0] && @dash < Gosu::milliseconds && @dash+150 > Gosu::milliseconds then
				@player.dash_up
				@dash = Gosu::milliseconds
				@dashlock[0] = false
			else
				@dash = Gosu::milliseconds
				@dashlock[0] = true
			end
		end
		if id == Gosu::Button::KbDown then
			if @dashlock[1] && @dash < Gosu::milliseconds && @dash+150 > Gosu::milliseconds then
				@player.dash_down
				@dash = Gosu::milliseconds
				@dashlock[1] = false
			else
				@dash = Gosu::milliseconds
				@dashlock[1] = true
			end
		end
		if id == Gosu::Button::KbLeft then
			if @dashlock[2] && @dash < Gosu::milliseconds && @dash+150 > Gosu::milliseconds then
				@player.dash_left
				@dash = Gosu::milliseconds
				@dashlock[2] = false
			else
				@dash = Gosu::milliseconds
				@dashlock[2] = true
			end
		end
		if id == Gosu::Button::KbRight then
			if @dashlock[3] && @dash < Gosu::milliseconds && @dash+150 > Gosu::milliseconds then
				@player.dash_right
				@dash = Gosu::milliseconds
				@dashlock[3] = false
			else
				@dash = Gosu::milliseconds
				@dashlock[3] = true
			end
		end
		self.close if id == Gosu::Button::KbEscape
	end
	
	def update
		@player.update
		@stars.update
		@director.update 
		if @time < Gosu::milliseconds/50 then # Pour que le score s'incrémente
											  # progressivement ( plus joli ).
			unless @score == @player.score
				@score += 1
			end
			@time = Gosu::milliseconds/50
		end
		if @time2 < Gosu::milliseconds/20 && @game_over then
			unless @score_total == @score
				@score_total += 1
			end
			@time2 = Gosu::milliseconds/20
		end
	end
	
	def game_over
		@game_over = true
	end
	
	def draw
		@player.draw
		@stars.draw
		@hud.draw("Life : #{@player.life}", 5, 5, 15)
		if @game_over then
			@font.draw("Game Over", @x_window / 2.0, @y_window / 2.0, 15)
			@hud.draw("Score total : #{@score_total}",  @x_window / 1.9, @y_window / 1.7, 15)
		end
		@hud.draw("Player : (#{@player.x_player};#{@player.y_player}) | bullet : #{@player.nb_bullet}", 5, 30, 15)
		@hud.draw("Score : #{@score}", 5, 55, 15)
	end
end

game = Game.new
game.show
