pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "./interfaces/ILendingPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/lifecycle/Pausable.sol";
import "./camToken.sol";
import "./erc20Stablecoin/erc20QiStablecoin.sol";
import "./interfaces/IAToken.sol";

contract camZapper is Ownable, Pausable, IERC721Receiver {
    using SafeMath for uint256;

    struct CamChain {
        IERC20 asset;
        IAToken amToken;
        camToken _camToken;
        erc20QiStablecoin camTokenVault;
    }

    mapping (bytes32 => CamChain) private _chainWhiteList;

    ILendingPool aavePolyPool = ILendingPool(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);

    event AssetZapped(address indexed asset, uint256 indexed amount, uint256 vaultId);
    event AssetUnZapped(address indexed asset, uint256 indexed amount, uint256 vaultId);

    function _camZapToVault(uint256 amount, uint256 vaultId, CamChain memory chain) internal whenNotPaused returns (uint256) {
        require(amount > 0, "You need to deposit at least some tokens");

        uint256 allowance = chain.asset.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");

        chain.asset.transferFrom(msg.sender, address(this), amount);
        chain.asset.approve(address(aavePolyPool), amount);

        aavePolyPool.deposit(address(chain.asset), amount, address(this), 0);
        chain.amToken.approve(address(chain._camToken), amount);

        chain._camToken.enter(amount);
        uint256 camTokenBal = chain._camToken.balanceOf(address(this));

        if(vaultId == 0){
            chain.asset.transferFrom(address(this), msg.sender, camTokenBal);
            emit AssetZapped(address(chain.asset), amount, vaultId);
        } else {
            chain._camToken.approve(address(chain.camTokenVault), camTokenBal);
            chain.camTokenVault.depositCollateral(vaultId, camTokenBal);
            emit AssetZapped(address(chain.asset), amount, vaultId);
        }

        return camTokenBal;
    }

    function _camZapFromVault(uint256 amount, uint256 vaultId, CamChain memory chain) internal whenNotPaused returns (uint256) {
        require(amount > 0, "You need to withdraw at least some tokens");
        require(chain.camTokenVault.getApproved(vaultId) == address(this), "Need to have approval");
        require(chain.camTokenVault.ownerOf(vaultId) == msg.sender, "You can only zap out of vaults you own");

        chain._camToken.approve(address(chain.camTokenVault), amount);
        chain.camTokenVault.safeTransferFrom(msg.sender, address(this), vaultId);

        uint256 camTokenBalanceBeforeWithdraw = chain._camToken.balanceOf(address(this));
        chain.camTokenVault.withdrawCollateral(vaultId, amount);
        uint256 camTokenBalanceToUnzap = chain._camToken.balanceOf(address(this)).sub(camTokenBalanceBeforeWithdraw);

        chain.camTokenVault.approve(msg.sender, vaultId);
        chain.camTokenVault.safeTransferFrom(address(this), msg.sender, vaultId);

        uint256 amTokenBalanceBeforeWithdraw = chain.amToken.balanceOf(address(this));
        chain._camToken.leave(camTokenBalanceToUnzap);
        uint256 amTokenBalanceToUnzap = chain.amToken.balanceOf(address(this)).sub(amTokenBalanceBeforeWithdraw);

        chain.amToken.approve(address(aavePolyPool), amTokenBalanceToUnzap);
        aavePolyPool.withdraw(address(chain.asset), amTokenBalanceToUnzap, msg.sender);


        emit AssetUnZapped(address(chain.asset), amount, vaultId);
        return chain.asset.balanceOf(msg.sender);
    }

    function _buildCamChain(address _asset, address _amAsset, address _camAsset, address _camAssetVault) internal returns (CamChain memory){
        CamChain memory chain;
        chain.asset = IERC20(_asset);
        chain.amToken = IAToken(_amAsset);
        chain._camToken = camToken(_camAsset);
        chain.camTokenVault = erc20QiStablecoin(_camAssetVault);
        return chain;
    }

    function _hashCamChain(CamChain memory chain) internal returns (bytes32){
        return keccak256(
            abi.encodePacked(address(chain.asset), address(chain.amToken), address(chain._camToken), address(chain.camTokenVault)));
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

    function camZapToVault(uint256 amount, uint256 vaultId, address _asset, address _amAsset, address _camAsset, address _camAssetVault) public whenNotPaused returns (uint256) {
        CamChain memory chain = _buildCamChain(_asset, _amAsset, _camAsset, _camAssetVault);
        require(isWhiteListed(chain), "camToken chain not in on allowable list");
        return _camZapToVault(amount, vaultId, chain);
    }

    function camZapFromVault(uint256 amount, uint256 vaultId, address _asset, address _amAsset, address _camAsset, address _camAssetVault) public whenNotPaused returns (uint256) {
        CamChain memory chain = _buildCamChain(_asset, _amAsset, _camAsset, _camAssetVault);
        require(isWhiteListed(chain), "camToken chain not in on allowable list");
        return _camZapFromVault(amount, vaultId, chain);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
