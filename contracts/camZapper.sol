pragma solidity 0.5.16;

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

    ILendingPool aavePolyPool = ILendingPool(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);

    event AssetZapped(address indexed asset, uint256 indexed amount, uint256 vaultId);

    function camZapToVault(uint256 amount, uint256 vaultIndex, address _asset, address _amAsset, address _camAsset, address _camAssetVault) public whenNotPaused returns (uint256) {
        CamChain memory chain;
        chain.asset = IERC20(_asset);
        chain.amToken = IERC20(_amAsset);
        chain._camToken = camToken(_camAsset);
        chain.camTokenVault = erc20QiStablecoin(_camAssetVault);

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

    function camZap(uint256 amount, address _asset, address _amAsset, address _camAsset, address _camAssetVault) public returns (uint256){
        return camZapToVault(amount, 0, _asset, _amAsset, _camAsset, _camAssetVault);
    }

    function pauseZapping() public onlyOwner {
        pause();
    }

    function resumeZapping() public onlyOwner {
        unpause();
    }

}
