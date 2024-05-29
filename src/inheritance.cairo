use starknet::{ContractAddress, get_caller_address};

#[derive(Copy, Drop, Serde, starknet::Store)]
struct Heirs {
    heir: ContractAddress,
    name: felt252,
    percentage: u256,
}

#[starknet::interface]
trait IInheritanceContract<ContractState> {
    fn add_heir(ref self: ContractState, new_heir: ContractAddress, name: felt252, percentage: u256);
    fn withdraw(ref self: ContractState);
}

#[starknet::contract]
mod Inheritance {
    use starknet::{ContractAddress, contract_address_const, get_caller_address, get_contract_address};
    use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
    use super::{IInheritanceContract, Heirs};

    #[storage]
    struct Storage {
        owner: ContractAddress,
        heirs: LegacyMap<u8, Heirs>,
        heirs_num: u8,   
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
    }
    #[abi(embed_v0)]
    impl InheritanceContract of IInheritanceContract<ContractState> {
        fn add_heir(ref self: ContractState, new_heir: ContractAddress, name: felt252, percentage: u256) {
            assert(get_caller_address() != self.owner.read(), 'Owner cant be heir');
            let curr_num_of_heirs = self.heirs_num.read() + 1;
            let heirs = Heirs {
                heir: new_heir,
                name,
                percentage
            };
            self.heirs.write(curr_num_of_heirs, heirs);
            self.heirs_num.write(curr_num_of_heirs);
        }

        fn withdraw(ref self: ContractState) {
            let eth_dispatcher = ERC20ABIDispatcher {
                contract_address: contract_address_const::<
                    0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
                >() // ETH Contract Address
            };
            eth_dispatcher.transfer(self.heirs.read(1).heir, (self.heirs.read(1).percentage * eth_dispatcher.balance_of(get_contract_address())) / 100);
        }
    }

}