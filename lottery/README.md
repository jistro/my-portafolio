# Contrato de rifa con causa

## Descripción

El siguente codigo se basa en el curso de Patrick Collins de desarrollo de contratos inteligentes usando solidity y foundry. Para ser mas especifico en la [leccion 9](https://youtu.be/sas02qSFZ74?t=11049).

## Que hace el contrato?

1. El contrato permite a los usuarios comprar boletos de rifa.
    1. cuando se compra un boleto un porcentaje (definido en el constructor) se guarda en el contrato para ser retirado despues por la ORG y el resto se guarda en el bote.
    2. el bote se dara al ganador de la rifa.
2. Despues de un x periodo de tiempo se hace la rifa.
    1. se elige un ganador de manera aleatoria y programabilistica.
3. Usaremos los servicios de Chainlink 
    1. [Chainlink VRF](https://docs.chain.link/docs/chainlink-vrf/) para generar numeros aleatorios. 
    2. [Chainlink Automation](https://docs.chain.link/chainlink-automation/introduction) para programar la rifa.