GAME_MESSAGES = {
    janken:        "「「じゃんけんほい！」」",
    aiko:          "「「あいこでしょ！」」",
    janken_win:    "じゃんけんに勝った！",
    janken_lose:   "じゃんけんに負けた…！",
    acchi:         "「あっちむいてほい！」",
    acchi_head:    "顔を向ける方向を決めてください",
    acchi_finger:  "指を指す方向を決めてください",
    game_reset:    "ゲームリセット",
    won_the_game:  "【勝者】プレイヤー\nおめでとうございます！",
    lost_the_game: "【勝者】AI\nあなたはゲームに負けました"
}
SELECT_MESSAGES = {
    janken: "0:（グー） 1:（チョキ） 2:（パー） 9:（ゲームを止める）",
    acchi: "0:（上） 1:（下） 2:（左） 3:（右） 9:（ゲームを止める）",
}
JANKEN_MOVES = {
    0 => "グー",
    1 => "チョキ",
    2 => "パー"
}
ACCHI_MOVES = {
    0 => "上",
    1 => "下",
    2 => "左",
    3 => "右"
}

# ゲーム進行を管理する
class GameProcess
    def initialize(process, player_input=nil, ai_move=nil, has_initiative=nil)
        @process = process
        @player_input = player_input
        @ai_move = ai_move
        @has_initiative = has_initiative
        check(@process)
    end

    private
    def check(process)
        case process
        when 0, 1
            janken_process
        when 2, 3
            acchi_process
        when 4, 5
            finish_process
        when 6
            bug_evasion
        when 9
            retire_game
        end
    end
    def janken_process
        player = Io.new(@process, @player_input, @ai_move, @has_initiative)
        unless irregular_pattern(player.choice)
            Janken.new(player.choice).proceed
        else
            check(player.choice)
        end
    end
    def acchi_process
        player = Io.new(@process, @player_input, @ai_move, @has_initiative)
        unless irregular_pattern(player.choice)
            Acchi.new(player.choice, player.new_initiative).proceed
        else
            check(player.choice)
        end
    end
    def finish_process
        Io.new(@process, @player_input, @ai_move, @has_initiative)
        return 0
    end
    def bug_evasion
        Io.new(6)
        GameProcess.new(0)
    end
    def retire_game
        Io.new(9)
        return 0
    end
    def irregular_pattern(result)
        result.to_i == 6 || result.to_i == 9
    end
end

# インターフェイスの入出力を行う（入力情報を保持する）
class Io
    attr_reader :choice, :new_initiative

    def initialize(process, player_input=nil, ai_move=nil, has_initiative=nil)
        @player_input = player_input
        @ai_move = ai_move
        @has_initiative = has_initiative
        check(process)
    end

    private
    def check(process)
        case process
        when 0
            janken_fight
        when 1
            aiko_fight
        when 2
            janken_lose_fight
        when 3
            janken_win_fight
        when 4
            game_win
        when 5
            game_lose
        when 6
            bug_evasion
        when 9
            retire_game
        end
    end
    def janken_fight
        unless @has_initiative.nil?
            line
            acchi_messages
            line
            puts GAME_MESSAGES[:game_reset]
            line
        end
        puts GAME_MESSAGES[:janken]
        puts SELECT_MESSAGES[:janken]
        @choice = gets.chomp
        choice_refinement
    end
    def aiko_fight
        line
        janken_messages
        line
        puts GAME_MESSAGES[:aiko]
        puts SELECT_MESSAGES[:janken]
        @choice = gets.chomp
        choice_refinement
    end
    def janken_lose_fight
        line
        janken_messages
        puts GAME_MESSAGES[:janken_lose]
        line
        puts GAME_MESSAGES[:acchi]
        puts GAME_MESSAGES[:acchi_head]
        puts SELECT_MESSAGES[:acchi]
        @choice = gets.chomp
        choice_refinement
        @new_initiative = false
    end
    def janken_win_fight
        line
        janken_messages
        puts GAME_MESSAGES[:janken_win]
        line
        puts GAME_MESSAGES[:acchi]
        puts GAME_MESSAGES[:acchi_finger]
        puts SELECT_MESSAGES[:acchi]
        @choice = gets.chomp
        choice_refinement
        @new_initiative = true
    end
    def game_win
        line
        acchi_messages
        line
        puts GAME_MESSAGES[:won_the_game]
    end
    def game_lose
        line
        acchi_messages
        line
        puts GAME_MESSAGES[:lost_the_game]
    end
    def line
        puts "------------------"
    end
    def janken_messages
        puts "プレイヤー: #{JANKEN_MOVES[@player_input]}を出しました"
        puts "AI: #{JANKEN_MOVES[@ai_move]}を出しました"
    end
    def acchi_messages
        if @has_initiative
            puts "プレイヤー: #{ACCHI_MOVES[@player_input]}を指差しました"
            puts "AI: #{ACCHI_MOVES[@ai_move]}を向きました"
        else
            puts "プレイヤー: #{ACCHI_MOVES[@player_input]}を向きました"
            puts "AI: #{ACCHI_MOVES[@ai_move]}を指差しました"
        end
    end
    def bug_evasion
        line
        puts "不正な入力が行われました"
        puts "ゲームをリセットします"
        line
    end
    def retire_game
        line
        puts "ゲームを終了します"
    end
    def choice_refinement
        @choice = @choice.empty? ? 6 : @choice
        @choice = @choice =~ /^[0-9]$/ ? @choice.to_i : 6
    end
end

# ゲーム2種のスーパークラス
class Game
    def initialize(player_input)
        @player_input = player_input
    end
    def proceed
        judge
        GameProcess.new(@result, @player_input, @ai_move, @has_initiative)
    end
end

# じゃんけんのロジックを管理し、結果を処理クラスへ渡す
class Janken < Game
    def initialize(player_input)
        super(player_input)
        @ai_move = Ai_move.new(0).result
    end
    
    private
    def judge
        # 範囲内の数値かどうかは、各ゲームロジックが判定する
        if (0..2) === @player_input
            # 1 = あいこ、2 = 負け、3 = 勝ち
            @result = ((@player_input - @ai_move + 3) % 3) + 1
        else
            @result = 6
        end
    end
end

# あっちむいてほいのロジックを管理し、結果を処理クラスへ渡す
class Acchi < Game
    def initialize(player_input, has_initiative)
        super(player_input)
        @ai_move = Ai_move.new(1).result
        @has_initiative = has_initiative
    end

    private
    def judge
        # 範囲内の数値かどうかは、各ゲームロジックが判定する
        if (0..3) === @player_input
            if @player_input == @ai_move
                #お互いの向きが合った時、主導権があれば勝ち、なければ負ける
                @result = @has_initiative ? 4 : 5
            else
                #向きが合っていない場合、じゃんけんに戻る
                @result = 0
            end
        else
            @result = 6
        end
    end
end

# コンピュータの結果を出力する
class Ai_move
    def initialize(game)
        @game = game
    end
    def result
        # 0 = じゃんけん、1 = あっちむいてほい
        case @game
        when 0
            return rand(3)
        when 1
            return rand(4)
        end
    end
end

# ゲーム開始
GameProcess.new(0)