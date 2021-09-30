pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "./interfaces/ILendingPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/lifecycle/Pausable.sol";
import "./camToken.sol";
import "./erc20Stablecoin/erc20QiStablecoin.sol";


contract camZapper is Ownable, Pausable {
    using SafeMath for uint256;

    struct CamChain {
        IERC20 asset;
        IERC20 amToken;
        camToken _camToken;
        erc20QiStablecoin camTokenVault;
    }

    mapping (bytes32 => CamChain) private _chainWhiteList;

    ILendingPool aavePolyPool = ILendingPool(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);

    event AssetZapped(address indexed asset, uint256 indexed amount, uint256 vaultId);

    function _camZapToVault(uint256 amount, uint256 vaultIndex, CamChain memory chain) internal whenNotPaused returns (uint256) {
        require(amount > 0, "You need to deposit at least some tokens");

        uint256 allowance = chain.asset.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");

        chain.asset.transferFrom(msg.sender, address(this), amount);
        chain.asset.approve(address(aavePolyPool), amount);

        aavePolyPool.deposit(address(chain.asset), amount, address(this), 0);
        chain.amToken.approve(address(chain._camToken), amount);

        chain._camToken.enter(amount);
        uint256 camTokenBal = chain._camToken.balanceOf(address(this));

        //Pre 0.6.0 Solidity Try-Catch via
        //https://ethereum.stackexchange.com/questions/78562/is-it-possible-to-perform-a-try-catch-in-solidity/78563
        (bool success, bytes memory returnData) =
        address(chain.camTokenVault).call( // This creates a low level call to the token
            abi.encodePacked( // This encodes the function to call and the parameters to pass to that function
                chain.camTokenVault.tokenOfOwnerByIndex.selector , // This is the function identifier of the function we want to call
                abi.encode(msg.sender, vaultIndex) // This encodes the parameter we want to pass to the function
            )
        );

        //Check if the zapper has at least one vault, if not we create it for them
        if(success){
            uint256 vaultId =  abi.decode(returnData, (uint256));
            chain._camToken.approve(address(chain.camTokenVault), camTokenBal);
            chain.camTokenVault.depositCollateral(vaultId, camTokenBal);
            emit AssetZapped(address(chain.asset), amount, vaultId);
        }
        else {
            //BUT we only create it if the vault they are looking for is the first one
            if(vaultIndex == 0){
                uint256 vaultId = chain.camTokenVault.createVault();
                chain._camToken.approve(address(chain.camTokenVault), camTokenBal);
                chain.camTokenVault.depositCollateral(vaultId, camTokenBal);
                chain.camTokenVault.safeTransferFrom(address(this), (msg.sender), vaultId);
                emit AssetZapped(address(chain.asset), amount, vaultId);
            } else {
                revert("Could not locate the vaultId provided");
            }
        }
        return chain._camToken.balanceOf(msg.sender);
    }

    function _buildCamChain(address _asset, address _amAsset, address _camAsset, address _camAssetVault) internal returns (CamChain memory){
        CamChain memory chain;
        chain.asset = IERC20(_asset);
        chain.amToken = IERC20(_amAsset);
        chain._camToken = camToken(_camAsset);
        chain.camTokenVault = erc20QiStablecoin(_camAssetVault);
        return chain;
    }

    function _hashCamChain(CamChain memory chain) internal returns (bytes32){
        return keccak256(
            abi.encodePacked(address(chain.asset) , address(chain.amToken), address(chain._camToken), address(chain.camTokenVault)));
    }

    function isWhiteListed(CamChain memory chain) public returns (bool){
        return address(_chainWhiteList[_hashCamChain(chain)].asset) != address(0x0);
    }

    function addChainToWhiteList(address _asset, address _amAsset, address _camAsset, address _camAssetVault) public onlyOwner {
        CamChain memory chain = _buildCamChain(_asset, _amAsset, _camAsset, _camAssetVault);
        if(!isWhiteListed(chain)){
            _chainWhiteList[_hashCamChain(chain)] = chain;
        } else {
            revert("Chain already in White List");
        }
    }

    function removeChainFromWhiteList(address _asset, address _amAsset, address _camAsset, address _camAssetVault) public onlyOwner {
        CamChain memory chain = _buildCamChain(_asset, _amAsset, _camAsset, _camAssetVault);

        if(isWhiteListed(chain)){
            delete _chainWhiteList[_hashCamChain(chain)];
        } else {
            revert("Chain not in white List");
        }
    }

    function pauseZapping() public onlyOwner {
        pause();
    }

    function resumeZapping() public onlyOwner {
        unpause();
    }

    function camZapToVault(uint256 amount, uint256 vaultIndex, address _asset, address _amAsset, address _camAsset, address _camAssetVault) public whenNotPaused returns (uint256) {
        CamChain memory chain = _buildCamChain(_asset, _amAsset, _camAsset, _camAssetVault);
        require(isWhiteListed(chain), "camToken chain not in on allowable list");
        return _camZapToVault(amount, vaultIndex, chain);
    }

    function camZap(uint256 amount, address _asset, address _amAsset, address _camAsset, address _camAssetVault) internal returns (uint256){
        CamChain memory chain = _buildCamChain(_asset, _amAsset, _camAsset, _camAssetVault);
        require(isWhiteListed(chain), "camToken chain not in on allowable list");
        return _camZapToVault(amount, 0, chain);
    }


}
