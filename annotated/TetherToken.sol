/**
 *Submitted for verification at Etherscan.io on 2017-11-28
*/

pragma solidity ^0.4.17; // https://docs.soliditylang.org/en/v0.4.18/

/*
 * TetherToken のデプロイ時に、このソースから確認できる初期化処理:
 *
 * 1. 継承元 Ownable のコンストラクタ Ownable() が実行され、owner に
 *    作成時の呼び出し元 msg.sender を設定する。複数の継承経路があっても
 *    同じ Ownable の初期化は一度だけ行われる。
 * 2. TetherToken のコンストラクタが4つの引数を受け取り、_totalSupply に
 *    _initialSupply、name に _name、symbol に _symbol、decimals に
 *    _decimals を設定する。
 * 3. TetherToken のコンストラクタ内において、balances[owner] に _initialSupply を設定し、初期供給量を最初の
 *    owner に割り当てる。続いて deprecated を false に設定する。
 *
 * コンストラクタ本体とは別に、paused、basisPointsRate、maximumFee には
 * ソース上で false または0が初期値として指定されている。未設定の状態変数は型の
 * デフォルト値から始まる（例: upgradedAddress はゼロアドレス、
 * allowed と isBlackListed の未設定要素はそれぞれ0とfalse）。
 *
 * 上記の値は、このソースだけから読める初期化の流れ。実際に渡された
 * _initialSupply、_name、_symbol、_decimals の値は作成取引で確認する。
 * SafeMath の各関数や送金関数は、デプロイ時に呼び出されない。
 */

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
/*
 * Solidity 0.4.18 の assert(condition) は、条件が true なら続行し、false なら
 * 例外で実行を中止する。公式資料では、内部エラーや成立すべき条件の検査に使う。
 * false のときは INVALID 命令 (0xfe) が実行され、呼び出し内の状態変更は
 * 巻き戻され、その呼び出しに残っていた gas はすべて消費される。
 * この SafeMath では、計算結果が成立すべき条件を満たすか確かめている。
 * 公式資料: https://docs.soliditylang.org/en/v0.4.18/control-structures.html#error-handling-assert-require-revert-and-exceptions
 */
library SafeMath {
    /*
     * a と b を掛ける。a が0なら結果も0なので先に返し、後の c / a で
     * ゼロ除算しないようにする。
     * uint256 の最大値は 2^256 - 1。この時代の算術では、掛け算が上限を超えると
     * 結果は 2^256 で割った余りに巻き戻る。例えば 2^255 * 2 は数学上は
     * 2^256 だが、uint256 に残る値 c は0になる。
     * 正しく計算できたなら c / a は元の b に戻る。上の例では 0 / 2^255 は0で
     * b の2と一致しないため、assert が失敗して誤った結果を使わせない。
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /*
     * a を b で割り、uint256 の整数商を返す（小数部分は切り捨て）。
     * b が0の場合、除算自体が失敗するので追加の assert は置いていない。
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /*
     * a から b を引く。b が a より大きいと uint256 の値が下限を越えて
     * 巻き戻るため、計算前に assert で拒否する。
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /*
     * a と b を足す。結果 c が a より小さければ uint256 の上限を超えて
     * 巻き戻ったと判断し、assert で失敗させる。
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
    /*
     * Solidity 0.4 系では、コントラクトと同名の Ownable() がコンストラクタ。
     * TetherToken のデプロイ時に継承元のこの処理が実行され、作成を呼び出した
     * アドレス（msg.sender）が最初の管理者 owner に設定される。
     * owner は onlyOwner による管理者操作の制限や、初期供給量の割り当てに使われる。
     * デプロイ後に通常の関数として呼び直すことはできない。
     */
    function Ownable() public {
        owner = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the owner.
      */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
/*
 * 末尾が ; の関数は、名前・引数・戻り値だけを示す宣言で、処理本体はない。
 * Solidity 0.4.18 では、未実装の関数を持つ contract は抽象コントラクトとなり、
 * 単体ではデプロイできない。継承先で未実装の関数をすべて実装すれば利用できる。
 * 公式資料: https://docs.soliditylang.org/en/v0.4.18/contracts.html#abstract-contracts
 *
 * ERC20Basic は transfer と balanceOf を宣言し、BasicToken が実装する。
 * totalSupply はさらに先の TetherToken が実装するため、BasicToken もこの時点では
 * 抽象コントラクト。_totalSupply の public getter と totalSupply() は別の関数。
 *
 * 名前に interface とあるが、これは interface キーワードによる定義ではない。
 * 状態変数 _totalSupply を持つため、同バージョンの厳密な interface の条件にも
 * 合致しない。ここでは関数の約束を示す抽象コントラクトとして使われる。
 * 公式資料: https://docs.soliditylang.org/en/v0.4.18/contracts.html#interfaces
 *
 * ERC-20 を実装するために、このような抽象コントラクトへ分けることは必須ではない。
 * TetherToken に最初から関数の本体をまとめて書くこともできる。
 * この分け方からは、基本機能と承認機能を段階的に追加して再利用しやすくする意図や、
 * 宣言した関数の実装漏れをコンパイラで検出する利点が考えられる。
 * ただし、作者が何を主目的にしたかは、このソースだけでは確認できない。
 */
contract ERC20Basic {
    // コントラクトの状態変数。値はストレージに保存され、継承先でも参照される。
    // public は外部から読み取るための getter を自動生成する。継承先で使える理由は getter ではなく、
    // この変数が継承され、public なのでコントラクト内部からも参照できるため。
    // getter は継承内での参照には不要。internal でも参照できるが、private だとできない。
    uint public _totalSupply;
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
/*
 * ERC20 は ERC20Basic の宣言を引き継ぎ、承認と委任送金の関数を追加で宣言する。
 * approve・allowance・transferFrom の本体は StandardToken にある。
 * StandardToken も totalSupply は未実装なので、最終的な TetherToken が実装する。
 * ERC20 も contract として宣言された抽象コントラクトであり、単体ではデプロイしない。
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
/*
 * BasicToken は残高の記録と、保有者本人が呼ぶ transfer の実装をまとめた土台。
 * balanceOf で残高を読め、transfer では残高の更新と送金手数料の計算を行う。
 * 他者に利用枠を与える approve や、その枠を使う transferFrom はここにはなく、
 * BasicToken を継承する StandardToken が追加する。
 */
contract BasicToken is Ownable, ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) public balances;

    // additional variables for use if transaction fees ever became necessary
    uint public basisPointsRate = 0;
    uint public maximumFee = 0;

    /*
     * modifier は Solidity の機能（構文）で、関数の実行前後に共通の処理や条件を加える仕組み。
     * modifier 自体は開発者がコントラクト内で定義できる。onlyOwner や onlyPayloadSize も
     * Solidity 組み込みの固定一覧から使うものではなく、このコード内で定義された独自 modifier。
     * 定義中の _; は、修飾された関数本体を実行する位置を表す。
     *
     * これは古い Solidity で使われた short address attack 対策。
     * 呼び出し側が address 引数をABIの32バイト枠より短くエンコードすると、
     * 後続の uint 引数の読み取り位置がずれ、送金額が意図と異なる値として解釈される
     * おそれがあった。この関数の引数は32バイト枠が2つ（address と uint）なので、
     * セレクター4バイトを含む最低68バイトがあるか確認する。
     * 正しいABI形式で呼ぶ通常のクライアントでは引数は所定の長さに埋められる。
     * このチェックは認可や宛先の妥当性を検証するものではない。
     * 詳細: https://ethereum.org/developers/docs/transactions/#the-data-field
     */
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    /*
     * 指定した宛先へトークンを送る。
     *
     * onlyPayloadSize(2 * 32) は、引数 _to と _value がそれぞれABI上32バイトで
     * 渡されていることを確認する。modifier内の _ は、このチェック後に関数本体を実行する印。
     * 関数セレクターの4バイトも含め、msg.data は最低68バイト必要。
     */
    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
        // 手数料を basisPointsRate / 10000 の割合で計算し、maximumFee を上限にする。
        // 現在の初期値は両方0なので、通常は fee は0。
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }

        // 送金元からは手数料込みの _value を引き、宛先には手数料を除いた額を渡す。
        uint sendAmount = _value.sub(fee);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);

        // 手数料がある場合は owner に加算し、その分の Transfer ログを記録する。
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            Transfer(msg.sender, owner, fee);
        }

        // 宛先への送金をログに記録する。残高不足などで SafeMath が失敗すれば、
        // トランザクション全体が取り消され、残高更新もログも残らない。
        Transfer(msg.sender, _to, sendAmount);
    }

    /*
     * 指定アドレスの残高を返す読み取り専用関数。
     * constant はこの古い Solidity 版での読み取り専用指定で、後の Solidity の view に相当する。
     * 状態を変更できず、外部から eth_call で読む場合はトランザクション送信もガス支払いも不要。
     * （コントラクト内から呼び出す場合は、その実行に必要なガスは呼び出し元の処理で消費される。）
     */
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based oncode by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
/*
 * StandardToken は ERC-20 で使う承認と委任送金の実装をまとめた部品。
 * BasicToken の直接送金に加え、approve で他者への利用枠を設定し、
 * allowance で残額を確認し、transferFrom でその枠を使って送金する。
 * TetherToken はこれを継承し、停止やブラックリストなどUSDT固有の処理を加える。
 * 「Standard」は標準的な機能を表す名前で、ERC-20が要求するコントラクト名ではない。
 */
contract StandardToken is BasicToken, ERC20 {

    /*
     * 所有者が spender（利用者）に使うことを許可した残高を記録する二重mapping。
     * allowed[所有者アドレス][spenderアドレス] が、spenderに残された利用可能額。
     * 所有者が approve(spender, 金額) を呼ぶと設定され、spenderが transferFrom を
     * 実行すると、通常は送金額分が減る。これは所有者の残高 balances とは別の許可枠。
     */
    mapping (address => mapping (address => uint)) public allowed;

    uint public constant MAX_UINT = 2**256 - 1;

    /*
     * 呼び出し元（spender）が、事前に許可された範囲で _from の残高を _to へ送る。
     * transfer と違い、msg.sender 自身の残高から送るとは限らない。
     * 例: Aliceが取引所にapproveした後、取引所が
     * transferFrom(Alice, Carol, 10) を呼ぶと、許可額とAliceの残高の範囲で送金する。
     */
    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
        // _from が msg.sender（spender）に与えた、現在の許可残額を取得する。
        var _allowance = allowed[_from][msg.sender];

        // 通常の許可額なら、下の SafeMath.sub が _value > _allowance の場合に失敗し、
        // トランザクション全体を取り消す。MAX_UINT は無制限許可の慣例として扱い、減らさない。

        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        /*
         * MAX_UINT（uint の最大値）を「無制限の利用許可」として扱う慣例。
         * 無制限許可なら送金のたびに残額を減らさず、それ以外は今回の送金額を差し引く。
         * そのため、無制限許可を出した spender は、許可を別途変更するまで繰り返し transferFrom できる。
         */
        if (_allowance < MAX_UINT) {
            // 無制限許可でなければ、許可残額を減らす。
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }

        // transfer と同じ手数料計算。手数料は owner、残額は _to に加算する。
        uint sendAmount = _value.sub(fee);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            Transfer(_from, owner, fee);
        }
        Transfer(_from, _to, sendAmount);
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    /*
     * 承認を与える側は呼び出し元（msg.sender）、_spender は承認を受ける側。
     * _spender が transferFrom で呼び出し元のトークンを使える上限を _value に設定する。
     */
    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        /*
         * 既存の許可額が残っている状態で、別の非ゼロ額へ直接変更することを拒否する。
         * 変更するときは、まず approve(_spender, 0) を確定させてから新しい額を設定する。
         *
         * 背景: 許可額100を50に変える取引が確定する前に、spenderが古い枠から100を
         * 使い切ると、その後の approve で新たに50が設定され、合計150を使える。
         * これは approve が許可残額を上書きすることと、取引の確定順が原因。
         *
         * この require だけで、その順序を完全に防げるわけではない。spenderが先に
         * 古い枠を使い切ると、実行時の許可残額は0となり、この条件を通過する。
         * 0への変更を確定させた後、古い枠の使用状況を確認して再承認する必要がある。
         */
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    /**
    * @dev Function to check the amount of tokens than an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint specifying the amount of tokens still available for the spender.
    */
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
/*
 * Pausable は paused 状態と、状態を確認する modifier を提供する。
 * 継承しただけで全関数が停止するわけではなく、whenNotPaused を付けた関数だけが
 * paused == true の間に実行を拒否される。
 * このファイルでは TetherToken.transfer と transferFrom の両方に付いている。
 * そのため停止中は、本人による送金も承認先による送金も拒否され、
 * このコントラクトの通常のUSDT送金はすべて止まる。
 * 一方、approve には付いていないため、
 * 停止中でも承認額は設定できる（その承認を使う送金は再開まで実行できない）。
 * pause / unpause は onlyOwner により owner だけが呼び出せる。
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract BlackList is Ownable, BasicToken {

    /////// Getters to allow the same blacklist to be used also by other contracts (including upgraded Tether) ///////
    function getBlackListStatus(address _maker) external constant returns (bool) {
        return isBlackListed[_maker];
    }

    function getOwner() external constant returns (address) {
        return owner;
    }

    mapping (address => bool) public isBlackListed;
    
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        /*
         * Solidity 0.4.17 の古いイベント記法。現在の Solidity では
         * emit AddedBlackList(_evilUser); と書く。
         *
         * addBlackList のトランザクション自体からも呼び出しは追えるが、
         * このイベントをレシートのログに残すことで、監視ツールや
         * インデクサーが「ブラックリストへの追加」として検索・購読しやすくなる。
         *
         * 実際に登録するのは上の mapping 更新であり、イベントはログ出力のみ。
         * また _user は indexed ではないため、イベント名やコントラクトで絞り込めるが、
         * ログのトピックだけで特定のユーザーアドレスに絞り込むことはできない。

         * 参考：
         https://docs.soliditylang.org/ja/latest/contracts.html#events
         https://tether.to/en/legal/
         */
        AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

}

/*
 * UpgradedStandardToken はコントラクト名であると同時に、コントラクト型としても使われる。
 * Solidity公式ドキュメント「Contract Types」:
 * https://docs.solidity.org/ja/latest/types.html#contract-types
 * ここでは旧 TetherToken が新コントラクトを呼ぶためのインターフェースとして、
 * 旧コントラクト経由で呼び出す関数の形（名前・引数）を宣言している。
 * 関数本体はなく、実際の処理は upgradedAddress が指す新コントラクトに実装される。
 */
contract UpgradedStandardToken is StandardToken{
    // those methods are called by the legacy contract
    // and they must ensure msg.sender to be the contract address
    function transferByLegacy(address from, address to, uint value) public;
    function transferFromByLegacy(address sender, address from, address spender, uint value) public;
    function approveByLegacy(address from, address spender, uint value) public;
}

// _totalSupply の宣言元は ERC20Basic。StandardToken -> BasicToken -> ERC20Basic と
// BlackList -> BasicToken -> ERC20Basic の両経路で継承しているため、ここで再宣言せず使える。
// 両経路に現れる ERC20Basic は共通の基底コントラクトで、_totalSupply が二つできるわけではない。
contract TetherToken is Pausable, StandardToken, BlackList {

    string public name;
    string public symbol;
    uint public decimals;
    address public upgradedAddress;
    /**
     * 旧コントラクトを廃止扱いにし、一部のERC20処理を upgradedAddress に転送するためのフラグ。
     * true にしても、このコントラクト自体が削除・停止されるわけではなく、状態も消えません。
     * deprecate() はフラグと移行先を設定し、transfer / balanceOf などが移行先へ転送します。
     * 転送されない関数もあるため、すべての機能が自動的に移行するわけではありません。
     */
    bool public deprecated;

    /**
     * コンストラクタ。新規デプロイ時に一度だけ実行され、デプロイ後に再実行できません。
     *
     * 引数はデプロイ時に指定されるため、このソースだけでは実際に使われた値は分かりません。
     * 手軽な確認方法は、対象チェーンのブロックエクスプローラーでコントラクトアドレスを検索し、
     * Contract Creator / 作成トランザクションを開くことです。ソースが検証済みなら、
     * constructor arguments が表示される場合もあります。
     *
     * エクスプローラーに依存せず確認するには、作成トランザクションのハッシュを特定して
     * RPC の eth_getTransactionByHash で input を取得し、引数をデコードします。
     * 標準RPCにはアドレスから作成トランザクションを逆引きする機能がないため、
     * ハッシュが不明なら過去ブロックの走査などが必要で、一般ユーザーには手軽ではありません。
     * ファクトリー経由の作成では実行トレースも必要です。エクスプローラーで得た情報は、
     * 独立したRPCや自分のノードでトランザクション・作成先アドレスを照合できます。
     *
     * name / symbol / decimals / totalSupply など、現在の状態は getter でも確認できますが、
     * 状態が変更されている場合など、元の引数と一致するとは限りません。
     * 初期供給量はすべてオーナーの残高に割り当てられます。
     *
     * @param _initialSupply 初期供給量
     * @param _name トークン名
     * @param _symbol トークンシンボル
     * @param _decimals 小数点桁数
     */
    function TetherToken(uint _initialSupply, string _name, string _symbol, uint _decimals) public {
        _totalSupply = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[owner] = _initialSupply;
        deprecated = false;
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transfer(address _to, uint _value) public whenNotPaused {
        require(!isBlackListed[msg.sender]);
        if (deprecated) {
            /*
             * upgradedAddress を UpgradedStandardToken 型として扱い、そこに実装された
             * transferByLegacy を呼ぶ。これは新コントラクトを作る記述ではなく、
             * アドレスにあるコントラクトをこの型の関数インターフェースで呼ぶためのキャスト。
                * コントラクトは、 address 型との間で明示的に変換できる。address 型はコントラクトのアドレスを表すだけで、関数呼び出しはできない。
             */
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            // 親コントラクト側の transfer を呼ぶ。super は継承元のコントラクトを指す。ここでは BasicToken の transfer。
            return super.transfer(_to, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transferFrom(address _from, address _to, uint _value) public whenNotPaused {
        require(!isBlackListed[_from]);
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function balanceOf(address who) public constant returns (uint) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    /* ここでも _spender は承認を受ける側。承認を与えるのは呼び出し元（msg.sender）。 */
    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        }
    }

    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        if (deprecated) {
            return StandardToken(upgradedAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }

    // deprecate current contract in favour of a new one
    function deprecate(address _upgradedAddress) public onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        Deprecate(_upgradedAddress);
    }

    // deprecate current contract if favour of a new one
    function totalSupply() public constant returns (uint) {
        if (deprecated) {
            return StandardToken(upgradedAddress).totalSupply();
        } else {
            return _totalSupply;
        }
    }

    // Issue a new amount of tokens
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be issued
    function issue(uint amount) public onlyOwner {
        require(_totalSupply + amount > _totalSupply);
        require(balances[owner] + amount > balances[owner]);

        balances[owner] += amount;
        _totalSupply += amount;
        Issue(amount);
    }

    // Redeem tokens.
    // These tokens are withdrawn from the owner address
    // if the balance must be enough to cover the redeem
    // or the call will fail.
    // @param _amount Number of tokens to be issued
    function redeem(uint amount) public onlyOwner {
        require(_totalSupply >= amount);
        require(balances[owner] >= amount);

        _totalSupply -= amount;
        balances[owner] -= amount;
        Redeem(amount);
    }

    function setParams(uint newBasisPoints, uint newMaxFee) public onlyOwner {
        // Ensure transparency by hardcoding limit beyond which fees can never be added
        require(newBasisPoints < 20);
        require(newMaxFee < 50);

        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(10**decimals);

        Params(basisPointsRate, maximumFee);
    }

    // Called when new token are issued
    event Issue(uint amount);

    // Called when tokens are redeemed
    event Redeem(uint amount);

    // Called when contract is deprecated
    event Deprecate(address newAddress);

    // Called if contract ever adds fees
    event Params(uint feeBasisPoints, uint maxFee);
}
