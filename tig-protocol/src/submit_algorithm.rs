use crate::{context::*, error::*};
use logging_timer::time;
use std::collections::HashSet;
use tig_structs::core::*;
use tig_utils::*;

#[time]
pub(crate) async fn execute<T: Context>(
    ctx: &T,
    player: &Player,
    details: AlgorithmDetails,
    code: String,
) -> ProtocolResult<String> {
    verify_challenge_exists(ctx, &details).await?;
    verify_submission_fee(ctx, player, &details).await?;
    let algorithm_id = ctx
        .add_algorithm_to_mempool(details, code)
        .await
        .unwrap_or_else(|e| panic!("add_algorithm_to_mempool error: {:?}", e));
    Ok(algorithm_id)
}

#[time]
async fn verify_challenge_exists<T: Context>(
    ctx: &T,
    details: &AlgorithmDetails,
) -> ProtocolResult<()> {
    let latest_block = ctx
        .get_block(BlockFilter::Latest, false)
        .await
        .unwrap_or_else(|e| panic!("get_block error: {:?}", e))
        .expect("Expecting latest block to exist");
    if !ctx
        .get_challenges(ChallengesFilter::Id(details.challenge_id.clone()), None)
        .await
        .unwrap_or_else(|e| panic!("get_challenges error: {:?}", e))
        .first()
        .is_some_and(|c| {
            c.state()
                .round_active
                .as_ref()
                .is_some_and(|r| *r <= latest_block.details.round)
        })
    {
        return Err(ProtocolError::InvalidChallenge {
            challenge_id: details.challenge_id.clone(),
        });
    }
    Ok(())
}

#[time]
async fn verify_submission_fee<T: Context>(
    ctx: &T,
    player: &Player,
    details: &AlgorithmDetails,
) -> ProtocolResult<()> {
    let block = ctx
        .get_block(BlockFilter::Latest, false)
        .await
        .unwrap_or_else(|e| panic!("get_block error: {:?}", e))
        .expect("No latest block found");

    if ctx
        .get_algorithms(
            AlgorithmsFilter::TxHash(details.tx_hash.clone()),
            None,
            false,
        )
        .await
        .unwrap_or_else(|e| panic!("get_algorithms error: {:?}", e))
        .first()
        .is_some()
    {
        return Err(ProtocolError::DuplicateTransaction {
            tx_hash: details.tx_hash.clone(),
        });
    }

    let transaction = ctx.get_transaction(&details.tx_hash).await.map_err(|_| {
        ProtocolError::InvalidTransaction {
            tx_hash: details.tx_hash.clone(),
        }
    })?;
    if player.id != transaction.sender {
        return Err(ProtocolError::InvalidTransactionSender {
            tx_hash: details.tx_hash.clone(),
            expected_sender: player.id.clone(),
            actual_sender: transaction.sender.clone(),
        });
    }
    let burn_address = block.config().erc20.burn_address.clone();
    if transaction.receiver != burn_address {
        return Err(ProtocolError::InvalidTransactionReceiver {
            tx_hash: details.tx_hash.clone(),
            expected_receiver: burn_address,
            actual_receiver: transaction.receiver.clone(),
        });
    }

    let expected_amount = block.config().algorithm_submissions.submission_fee;
    if transaction.amount != expected_amount {
        return Err(ProtocolError::InvalidTransactionAmount {
            tx_hash: details.tx_hash.clone(),
            expected_amount: jsonify(&expected_amount),
            actual_amount: jsonify(&transaction.amount),
        });
    }
    Ok(())
}
