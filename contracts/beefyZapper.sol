pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/lifecycle/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IBeefyVault.sol";
import "./crosschainStablecoin.sol";

contract beefyZapper is Ownable, Pausable {
    using SafeMath for uint256;

    struct MooChain {
        IERC20 asset;
        IBeefyVault mooToken;
        crosschainStablecoin mooTokenVault;
    }

    mapping (bytes32 => MooChain) private _chainWhiteList;

    event AssetZapped(address indexed asset, uint256 indexed amount, uint256 vaultId);

    function _beefyZapToVault(uint256 amount, uint256 vaultIndex, MooChain memory chain) internal whenNotPaused returns (uint256) {
        require(amount > 0, "You need to deposit at least some tokens");

        uint256 allowance = chain.asset.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");

        chain.asset.transferFrom(msg.sender, address(this), amount);

        chain.asset.approve(address(chain.mooToken), amount);
        chain.mooToken.deposit(amount);
        uint256 mooTokenBal = chain.mooToken.balanceOf(address(this));

       //Pre 0.6.0 Solidity Try-Catch via
       //https://ethereum.stackexchange.com/questions/78562/is-it-possible-to-perform-a-try-catch-in-solidity/78563
        (bool success, bytes memory returnData) = address(chain.mooTokenVault).call(// This creates a low level call to the token
            abi.encodePacked(// This encodes the function to call and the parameters to pass to that function
                chain.mooTokenVault.tokenOfOwnerByIndex.selector, // This is the function identifier of the function we want to call
                abi.encode(msg.sender, vaultIndex) // This encodes the parameter we want to pass to the function
        ));

            //Check if the zapper has at least one vault, if not we create it for them
        if (success){
            uint256 vaultId = abi.decode(returnData, (uint256));
            chain.mooToken.approve(address(chain.mooTokenVault), mooTokenBal);
            chain.mooTokenVault.depositCollateral(vaultId, mooTokenBal);
            emit AssetZapped(address(chain.asset), amount, vaultId);
        }
        else {
            revert("Could not locate the vaultId provided");
        }
        return chain.mooToken.balanceOf(msg.sender);
    }

    function _buildMooChain(address _asset, address _mooAsset, address _mooAssetVault) internal returns (MooChain memory){
        MooChain memory chain;
        chain.asset = IERC20(_asset);
        chain.mooToken = IBeefyVault(_mooAsset);
        chain.mooTokenVault = crosschainStablecoin(_mooAssetVault);
        return chain;
    }

    function _hashMooChain(MooChain memory chain) internal returns (bytes32){
        return keccak256(
            abi.encodePacked(address(chain.asset) , address(chain.mooToken), address(chain.mooTokenVault)));
    }

    function isWhiteListed(MooChain memory chain) public returns (bool){
        return address(_chainWhiteList[_hashMooChain(chain)].asset) != address(0x0);
    }

    function addChainToWhiteList(address _asset, address _mooAsset, address _mooAssetVault) public onlyOwner {
        MooChain memory chain = _buildMooChain(_asset, _mooAsset, _mooAssetVault);
        if(!isWhiteListed(chain)){
            _chainWhiteList[_hashMooChain(chain)] = chain;
        } else {
            revert("Chain already in White List");
        }
    }

    function removeChainFromWhiteList(address _asset, address _mooAsset, address _mooAssetVault) public onlyOwner {
        MooChain memory chain = _buildMooChain(_asset, _mooAsset, _mooAssetVault);
        if(isWhiteListed(chain)){
            delete _chainWhiteList[_hashMooChain(chain)];
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

    function beefyZapToVault(uint256 amount, uint256 vaultIndex, address _asset, address _mooAsset, address _mooAssetVault) public whenNotPaused returns (uint256) {
        MooChain memory chain = _buildMooChain(_asset, _mooAsset, _mooAssetVault);
        require(isWhiteListed(chain), "mooToken chain not in on allowable list");
        return _beefyZapToVault(amount, vaultIndex, chain);
    }

}
