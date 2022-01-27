// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {LibCustomArt} from "./libraries/LibCustomArt.sol";
import {Base64} from 'base64/base64.sol';

contract Persona is ERC721 {

    uint256 currentTokenId;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    /*///////////////////////////////////////////////////////////////
                                VIEW
    //////////////////////////////////////////////////////////////*/

    function getPersona(address target) public returns (uint256 personaId) {}

    function isAuthorized(uint256 personaId, address target) public returns (bool authorized) {}

    /*///////////////////////////////////////////////////////////////
                                MUTATION
    //////////////////////////////////////////////////////////////*/

    function impersonate(uint256 personaId) public {}

    function deimpersonate() public {}

    function authorize(uint256 personaId, address target, address gameContract) public {}

    function authorize(uint256 personaId, address target, address gameContract, bytes4[] memory fnSignatures) public {}

    function authorizeWithHook(uint256 personaId, address target, address hookContract, bytes4 callbackFunction) public {}

    function deauthorize(uint256 personaId, address target) public {}

    /*///////////////////////////////////////////////////////////////
                                ART
    //////////////////////////////////////////////////////////////*/

    // Returns the gradient for a given address.
    function gradientForAddress(address user) public pure returns (bytes[4] memory) {
        return LibCustomArt.gradientForAddress(user);
    }

    // Generates the artwork for a given address.
    // Currently the SVG is Zora's Zorb svg as a filler.
    function artForAddress(address user) public view returns (string memory) {
        bytes[4] memory colors = gradientForAddress(user);
        string memory encoded = Base64.encode(
            bytes(
                abi.encodePacked(
                    '<svg width="619" height="809" viewBox="0 0 619 809" fill="none" xmlns="http://www.w3.org/2000/svg">'
                    '<rect width="619" height="809" rx="10" fill="#1A1F25"/>'
                    '<mask id="b" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="35" y="32" width="549" height="590">'
                        '<path d="M36 549.5V43c0-5.523 4.477-10 10-10h527c5.523 0 10 4.477 10 10v568c0 5.523-4.477 10-10 10H450.059c-1.631 0-3.237-.399-4.679-1.162l-111.756-59.176a10.008 10.008 0 0 0-4.68-1.162H46c-5.523 0-10-4.477-10-10Z" fill="#000" stroke="url(#a)" stroke-width="2"/>'
                    '</mask>'
                    '<g mask="url(#b)">'
                        '<g filter="url(#c)">'
                        '<circle cx="82" cy="405" r="175" fill="#167C33"/>'
                        '</g>'
                        '<g filter="url(#d)">'
                        '<circle cx="161" cy="67" r="175" fill="#B6B147"/>'
                        '</g>'
                        '<g filter="url(#e)">'
                        '<circle cx="445" cy="502" r="175" fill="#6D486D"/>'
                        '</g>'
                        '<g filter="url(#f)">'
                        '<circle cx="530" cy="175" r="175" fill="#84C3F7"/>'
                        '</g>'
                    '</g>'
                    '<path d="M36 549.5V43c0-5.523 4.477-10 10-10h527c5.523 0 10 4.477 10 10v568c0 5.523-4.477 10-10 10H450.059c-1.631 0-3.237-.399-4.679-1.162l-111.756-59.176a10.008 10.008 0 0 0-4.68-1.162H46c-5.523 0-10-4.477-10-10Z" stroke="url(#g)" stroke-width="2"/>'
                    '<text fill="#fff" xml:space="preserve" style="white-space:pre" font-size="48" font-weight="bold" letter-spacing="-.025em"><tspan x="36" y="620.78">PERSONA</tspan></text>'
                    '<path fill="url(#h)" d="M93 755.88h11.247V808H93z"/>'
                    '<path fill="url(#i)" d="M106.637 736h11.247v72h-11.247z"/>'
                    '<path fill="url(#j)" d="M120.274 746.746h11.247V808h-11.247z"/>'
                    '<path fill="url(#k)" d="M133.911 739.761h11.247V808h-11.247z"/>'
                    '<path fill="url(#l)" d="M147.549 775.761h11.247V808h-11.247z"/>'
                    '<path fill="url(#m)" d="M161.186 758.03h11.247V808h-11.247z"/>'
                    '<path fill="url(#n)" d="M174.823 746.746h11.247V808h-11.247z"/>'
                    '<path fill="url(#o)" d="M188.46 736h11.247v72H188.46z"/>'
                    '<path fill="url(#p)" d="M202.097 751.582h11.247V808h-11.247z"/>'
                    '<path fill="url(#q)" d="M215.734 741.91h11.247V808h-11.247z"/>'
                    '<path fill="url(#r)" d="M229.372 738.149h11.247V808h-11.247z"/>'
                    '<path fill="url(#s)" d="M243.009 736h11.247v72h-11.247z"/>'
                    '<path fill="url(#t)" d="M256.646 751.582h11.247V808h-11.247z"/>'
                    '<path fill="url(#u)" d="M270.283 785.433h11.247V808h-11.247z"/>'
                    '<path fill="url(#v)" d="M283.92 761.792h11.247v46.209H283.92z"/>'
                    '<path fill="url(#w)" d="M297.558 753.731h11.247V808h-11.247z"/>'
                    '<path fill="url(#x)" d="M311.195 741.91h11.247V808h-11.247z"/>'
                    '<path fill="url(#y)" d="M324.832 736h11.247v72h-11.247z"/>'
                    '<path fill="url(#z)" d="M338.469 760.179h11.247V808h-11.247z"/>'
                    '<path fill="url(#A)" d="M352.107 736h11.247v72h-11.247z"/>'
                    '<path fill="url(#B)" d="M365.743 781.672h11.247V808h-11.247z"/>'
                    '<path fill="url(#C)" d="M379.381 755.88h11.247V808h-11.247z"/>'
                    '<path fill="url(#D)" d="M393.018 748.359h11.247v59.642h-11.247z"/>'
                    '<path fill="url(#E)" d="M406.655 761.792h11.247v46.209h-11.247z"/>'
                    '<path fill="url(#F)" d="M420.292 748.359h11.247v59.642h-11.247z"/>'
                    '<path fill="url(#G)" d="M433.93 758.03h11.247V808H433.93z"/>'
                    '<path fill="url(#H)" d="M447.567 748.359h11.247v59.642h-11.247z"/>'
                    '<path fill="url(#I)" d="M461.204 761.792h11.247v46.209h-11.247z"/>'
                    '<path fill="url(#J)" d="M474.841 746.746h11.247V808h-11.247z"/>'
                    '<path fill="url(#K)" d="M488.478 773.612h11.247V808h-11.247z"/>'
                    '<path fill="url(#L)" d="M502.115 749.97h11.247V808h-11.247z"/>'
                    '<path fill="url(#M)" d="M515.753 736H527v72h-11.247z"/>'
                    '<path fill="#000" d="M490 48h26v38h-26z"/>'
                    '<text transform="translate(491 53.413)" fill="#fff" xml:space="preserve" style="white-space:pre" font-family="Verily Serif Mono" font-size="24" letter-spacing=".06em"><tspan x="4.495" y="23.304">*</tspan></text>'
                    '<path fill="#000" d="M516 48h26v38h-26z"/>'
                    '<text transform="translate(517 53.413)" fill="#fff" xml:space="preserve" style="white-space:pre" font-family="Verily Serif Mono" font-size="24" letter-spacing=".06em"><tspan x="4.495" y="23.304">*</tspan></text>'
                    '<path fill="#000" d="M542 48h26v38h-26z"/>'
                    '<text transform="translate(543 53.413)" fill="#fff" xml:space="preserve" style="white-space:pre" font-family="Verily Serif Mono" font-size="24" letter-spacing=".06em"><tspan x="4.495" y="23.304">*</tspan></text>'
                    '<text transform="rotate(-90 606.5 13.5)" fill="#fff" xml:space="preserve" style="white-space:pre" font-size="14" letter-spacing="0em"><tspan x="0" y="15.04">0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B</tspan></text>'
                    '<path stroke="url(#N)" d="M499 808.5h114"/>'
                    '<path stroke="url(#O)" d="M498 808.5H6"/>'
                    '<path stroke="url(#P)" d="M1.5 16v770"/>'
                    '<path stroke="url(#Q)" d="M464 .5H19"/>'
                    '<defs>'
                        '<linearGradient id="a" x1="309.5" y1="33" x2="309.5" y2="621" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#D0ECFF"/>'
                        '<stop offset="1" stop-opacity="0"/>'
                        '</linearGradient>'
                        '<linearGradient id="g" x1="309.5" y1="33" x2="309.5" y2="621" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#D0ECFF"/>'
                        '<stop offset="1" stop-opacity="0"/>'
                        '</linearGradient>'
                        '<linearGradient id="h" x1="98.624" y1="755.88" x2="98.624" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="i" x1="112.261" y1="736" x2="112.261" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="j" x1="125.898" y1="746.746" x2="125.898" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="k" x1="139.535" y1="739.761" x2="139.535" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="l" x1="153.172" y1="775.761" x2="153.172" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="m" x1="166.809" y1="758.03" x2="166.809" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="n" x1="180.447" y1="746.746" x2="180.447" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="o" x1="194.084" y1="736" x2="194.084" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="p" x1="207.721" y1="751.582" x2="207.721" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="q" x1="221.358" y1="741.91" x2="221.358" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="r" x1="234.996" y1="738.149" x2="234.996" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="s" x1="248.633" y1="736" x2="248.633" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="t" x1="262.27" y1="751.582" x2="262.27" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="u" x1="275.907" y1="785.433" x2="275.907" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="v" x1="289.544" y1="761.792" x2="289.544" y2="808.001" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="w" x1="303.181" y1="753.731" x2="303.181" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="x" x1="316.818" y1="741.91" x2="316.818" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="y" x1="330.456" y1="736" x2="330.456" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="z" x1="344.093" y1="760.179" x2="344.093" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="A" x1="357.73" y1="736" x2="357.73" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="B" x1="371.367" y1="781.672" x2="371.367" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="C" x1="385.004" y1="755.88" x2="385.004" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="D" x1="398.642" y1="748.359" x2="398.642" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="E" x1="412.279" y1="761.792" x2="412.279" y2="808.001" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="F" x1="425.916" y1="748.359" x2="425.916" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="G" x1="439.553" y1="758.03" x2="439.553" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="H" x1="453.19" y1="748.359" x2="453.19" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="I" x1="466.827" y1="761.792" x2="466.827" y2="808.001" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="J" x1="480.465" y1="746.746" x2="480.465" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="K" x1="494.102" y1="773.612" x2="494.102" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="L" x1="507.739" y1="749.97" x2="507.739" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="M" x1="521.376" y1="736" x2="521.376" y2="808" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#F2D598"/>'
                        '<stop offset="1" stop-color="#D2BA85"/>'
                        '</linearGradient>'
                        '<linearGradient id="N" x1="510.5" y1="809" x2="614" y2="809" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#606060"/>'
                        '<stop offset="1" stop-color="#606060" stop-opacity="0"/>'
                        '</linearGradient>'
                        '<linearGradient id="O" x1="448.368" y1="808" x2="1.684" y2="807.997" gradientUnits="userSpaceOnUse">'
                        '<stop stop-color="#606060"/>'
                        '<stop offset="1" stop-color="#606060" stop-opacity="0"/>'
                        '</linearGradient>'
                        '<filter id="c" x="-420" y="-97" width="1004" height="1004" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">'
                        '<feFlood flood-opacity="0" result="BackgroundImageFix"/>'
                        '<feBlend in="SourceGraphic" in2="BackgroundImageFix" result="shape"/>'
                        '<feGaussianBlur stdDeviation="163.5" result="effect1_foregroundBlur_44_4"/>'
                        '</filter>'
                        '<filter id="d" x="-341" y="-435" width="1004" height="1004" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">'
                        '<feFlood flood-opacity="0" result="BackgroundImageFix"/>'
                        '<feBlend in="SourceGraphic" in2="BackgroundImageFix" result="shape"/>'
                        '<feGaussianBlur stdDeviation="163.5" result="effect1_foregroundBlur_44_4"/>'
                        '</filter>'
                        '<filter id="e" x="-57" y="0" width="1004" height="1004" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">'
                        '<feFlood flood-opacity="0" result="BackgroundImageFix"/>'
                        '<feBlend in="SourceGraphic" in2="BackgroundImageFix" result="shape"/>'
                        '<feGaussianBlur stdDeviation="163.5" result="effect1_foregroundBlur_44_4"/>'
                        '</filter>'
                        '<filter id="f" x="28" y="-327" width="1004" height="1004" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">'
                        '<feFlood flood-opacity="0" result="BackgroundImageFix"/>'
                        '<feBlend in="SourceGraphic" in2="BackgroundImageFix" result="shape"/>'
                        '<feGaussianBlur stdDeviation="163.5" result="effect1_foregroundBlur_44_4"/>'
                        '</filter>'
                        '<radialGradient id="P" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="rotate(-15.504 1283.057 193.365) scale(151.513 116665)">'
                        '<stop stop-color="#fff"/>'
                        '<stop offset="1" stop-opacity="0"/>'
                        '</radialGradient>'
                        '<radialGradient id="Q" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="matrix(23.40576 145.99977 -68216.167 10935.98478 270.974 -6)">'
                        '<stop stop-color="#fff"/>'
                        '<stop offset="1" stop-opacity="0"/>'
                        '</radialGradient>'
                    '</defs>'
                    '</svg>'
                )
            )
        );
        return string(abi.encodePacked("data:image/svg+xml;base64,", encoded));
    }

    function tokenURI(uint256 id)
        public
        view
        override
        returns (string memory)
    {
        require(ownerOf[id] != address(0), "Token does not exist.");

        string memory image = artForAddress(ownerOf[id]); 

        return
            string(
                abi.encodePacked(
                    '{"name":"',
                    name,
                    '", "description":"',
                    'Sample description for Persona NFT',
                    '", "image": "',
                    'data:image/svg+xml;base64,',
                    image,
                    '"}'
                )
            );
    }
}